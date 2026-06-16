import { User, DayLog } from '../models/index.js'
import { getCache, setCache, deleteCache, CACHE_KEYS, TTL } from '../config/redis.js'
import { getWeekRange } from '../utils/dateHelper.js'

export const leaderboardService = {
  // ── Friends leaderboard (by current streak) ──────────────────────
  getFriendsLeaderboard: async (userId) => {
    const cacheKey = CACHE_KEYS.leaderboard(`friends:${userId}`)
    const cached = await getCache(cacheKey)
    if (cached) return cached

    const user = await User.findById(userId).select('friendIds').lean()
    const allIds = [userId, ...user.friendIds]

    const users = await User.find({ _id: { $in: allIds }, isActive: true })
      .select('name username profilePicture currentStreakDays bestStreakDays level')
      .lean()

    const ranked = users
      .sort((a, b) => b.currentStreakDays - a.currentStreakDays)
      .map((u, i) => ({
        rank: i + 1,
        userId: u._id,
        name: u.name,
        username: u.username,
        profilePicture: u.profilePicture,
        currentStreak: u.currentStreakDays,
        bestStreak: u.bestStreakDays,
        level: u.level,
        isMe: String(u._id) === String(userId),
      }))

    await setCache(cacheKey, ranked, TTL.MEDIUM)
    return ranked
  },

  // ── Friends weekly leaderboard (by productive days this week) ────
  getFriendsWeeklyLeaderboard: async (userId) => {
    const cacheKey = CACHE_KEYS.leaderboard(`friends:weekly:${userId}`)
    const cached = await getCache(cacheKey)
    if (cached) return cached

    const user = await User.findById(userId).select('friendIds').lean()
    const allIds = [userId, ...user.friendIds]

    const { from, to } = getWeekRange()

    const [users, weeklyLogs] = await Promise.all([
      User.find({ _id: { $in: allIds } })
        .select('name username profilePicture currentStreakDays level')
        .lean(),
      DayLog.aggregate([
        {
          $match: {
            userId: { $in: allIds.map(id => id.toString ? id : id) },
            date: { $gte: from, $lte: to },
            isProductiveDay: true,
          },
        },
        {
          $group: {
            _id: '$userId',
            productiveDays: { $sum: 1 },
            avgScore: { $avg: '$productivityScore' },
          },
        },
      ]),
    ])

    const logMap = {}
    for (const log of weeklyLogs) {
      logMap[String(log._id)] = log
    }

    const ranked = users
      .map((u) => ({
        userId: u._id,
        name: u.name,
        username: u.username,
        profilePicture: u.profilePicture,
        currentStreak: u.currentStreakDays,
        level: u.level,
        productiveDaysThisWeek: logMap[String(u._id)]?.productiveDays || 0,
        avgScoreThisWeek: Math.round(logMap[String(u._id)]?.avgScore || 0),
        isMe: String(u._id) === String(userId),
      }))
      .sort((a, b) => b.productiveDaysThisWeek - a.productiveDaysThisWeek)
      .map((u, i) => ({ ...u, rank: i + 1 }))

    await setCache(cacheKey, ranked, TTL.MEDIUM)
    return ranked
  },

  // ── Global leaderboard (paginated) ───────────────────────────────
  getGlobalLeaderboard: async ({ page, limit }) => {
    const cacheKey = CACHE_KEYS.leaderboard(`global:${page}`)
    const cached = await getCache(cacheKey)
    if (cached) return cached

    const skip = (Number(page) - 1) * Number(limit)

    const [users, total] = await Promise.all([
      User.find({ isActive: true, isDeleted: false })
        .select('name username profilePicture currentStreakDays bestStreakDays level')
        .sort({ currentStreakDays: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      User.countDocuments({ isActive: true, isDeleted: false }),
    ])

    const ranked = users.map((u, i) => ({
      rank: skip + i + 1,
      userId: u._id,
      name: u.name,
      username: u.username,
      profilePicture: u.profilePicture,
      currentStreak: u.currentStreakDays,
      bestStreak: u.bestStreakDays,
      level: u.level,
    }))

    const result = { ranked, total, page: Number(page), limit: Number(limit) }
    await setCache(cacheKey, result, TTL.MEDIUM)
    return result
  },

  // ── Category leaderboard (friends ranked by category streak) ─────
  getCategoryLeaderboard: async (userId, category) => {
    const cacheKey = CACHE_KEYS.leaderboard(`category:${category}:${userId}`)
    const cached = await getCache(cacheKey)
    if (cached) return cached

    const user = await User.findById(userId).select('friendIds').lean()
    const allIds = [userId, ...user.friendIds]

    const { Habit, HabitLog } = await import('../models/index.js')
    const { getWeekRange } = await import('../utils/dateHelper.js')
    const { from, to } = getWeekRange()

    // Get habits of category for all users in group
    const habits = await Habit.find({
      userId: { $in: allIds },
      category,
      isActive: true,
    }).select('_id userId').lean()

    const habitIds = habits.map((h) => h._id)

    const logs = await HabitLog.aggregate([
      {
        $match: {
          habitId: { $in: habitIds },
          date: { $gte: from, $lte: to },
          isCompleted: true,
        },
      },
      {
        $group: {
          _id: '$userId',
          completedDays: { $sum: 1 },
        },
      },
    ])

    const logMap = {}
    for (const log of logs) logMap[String(log._id)] = log.completedDays

    const users = await User.find({ _id: { $in: allIds } })
      .select('name username profilePicture currentStreakDays level')
      .lean()

    const ranked = users
      .map((u) => ({
        userId: u._id,
        name: u.name,
        username: u.username,
        profilePicture: u.profilePicture,
        currentStreak: u.currentStreakDays,
        level: u.level,
        completedDaysThisWeek: logMap[String(u._id)] || 0,
        isMe: String(u._id) === String(userId),
      }))
      .sort((a, b) => b.completedDaysThisWeek - a.completedDaysThisWeek)
      .map((u, i) => ({ ...u, rank: i + 1 }))

    await setCache(cacheKey, ranked, TTL.MEDIUM)
    return ranked
  },

  // ── Invalidate user leaderboard cache ────────────────────────────
  // Called after streak update so board stays fresh
  invalidateForUser: async (userId) => {
    await Promise.all([
      deleteCache(CACHE_KEYS.leaderboard(`friends:${userId}`)),
      deleteCache(CACHE_KEYS.leaderboard(`friends:weekly:${userId}`)),
    ])
  },
}