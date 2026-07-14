import { Streak, DayLog, HabitLog, User, Habit } from '../models/index.js'
import { getTodayDate, getPreviousDate, daysBetween } from '../utils/dateHelper.js'
import { deleteCache, getCache, CACHE_KEYS, setCache, TTL } from '../config/redis.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'
import { enqueueAchievementCheck } from '../config/bullmq.js'

export const streakService = {
  // ── Get overall app streak ───────────────────────────────────────
  getOverallStreak: async (userId) => {
    const cached = await getCache(CACHE_KEYS.userStreak(userId))
    if (cached) return cached

    let streak = await Streak.findOne({ userId, habitId: null }).lean()
    if (!streak) {
      streak = await Streak.create({ userId, habitId: null })
    }

    await setCache(CACHE_KEYS.userStreak(userId), streak, TTL.SHORT)
    return streak
  },

  // ── Get habit streak ─────────────────────────────────────────────
  getHabitStreak: async (userId, habitId) => {
    const cached = await getCache(CACHE_KEYS.habitStreak(userId, habitId))
    if (cached) return cached

    let streak = await Streak.findOne({ userId, habitId }).lean()
    if (!streak) {
      streak = await Streak.create({ userId, habitId })
    }

    await setCache(CACHE_KEYS.habitStreak(userId, habitId), streak, TTL.SHORT)
    return streak
  },

  // ── Get streak summary (all habits) ─────────────────────────────
  getStreakSummary: async (userId) => {
    const streaks = await Streak.find({ userId }).lean()
    return streaks
  },

  // ── Get overall history ──────────────────────────────────────────
  getOverallHistory: async (userId) => {
    const streak = await Streak.findOne({ userId, habitId: null }).lean()
    return streak?.streakHistory || []
  },

  // ── Get habit streak history ─────────────────────────────────────
  getHabitStreakHistory: async (userId, habitId) => {
    const streak = await Streak.findOne({ userId, habitId }).lean()
    return streak?.streakHistory || []
  },

  // ── Get upcoming milestones ──────────────────────────────────────
  getMilestones: async (userId) => {
    const MILESTONES = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365]
    const user = await User.findById(userId).select('currentStreakDays').lean()
    const current = user.currentStreakDays || 0

    const next = MILESTONES.filter((m) => m > current)
    return next.map((m) => ({
      days: m,
      daysAway: m - current,
      label: getMilestoneLabel(m),
    }))
  },

  // ── Get friend rank ───────────────────────────────────────────────
  getFriendRank: async (userId) => {
    const user = await User.findById(userId).select('friendIds currentStreakDays').lean()
    const allIds = [userId, ...user.friendIds]

    const users = await User.find({ _id: { $in: allIds } })
      .select('name username profilePicture currentStreakDays')
      .lean()

    const ranked = users
      .sort((a, b) => b.currentStreakDays - a.currentStreakDays)
      .map((u, i) => ({ ...u, rank: i + 1 }))

    const myRank = ranked.find((u) => u._id.toString() === userId.toString())
    return { rank: myRank?.rank, total: ranked.length, leaderboard: ranked }
  },

  // ── Handle habit completed ───────────────────────────────────────
  handleHabitComplete: async (userId, habitId, date) => {
    let streak = await Streak.findOne({ userId, habitId })
    if (!streak) streak = new Streak({ userId, habitId })

    const yesterday = getPreviousDate(date)
    const wasYesterdayComplete = await HabitLog.findOne({
      userId,
      habitId,
      date: yesterday,
      isCompleted: true,
    }).lean()

    const dayLog = await DayLog.findOne({ userId, date: yesterday }).lean()
    const yesterdayProtected = dayLog?.isFreezeDay || dayLog?.isCheatDay

    const continuesStreak = wasYesterdayComplete || yesterdayProtected || streak.currentStreakCount === 0

    if (continuesStreak) {
      if (!streak.currentStreakStart) streak.currentStreakStart = date
      streak.currentStreakEnd = date
      streak.currentStreakCount += 1
    } else {
      if (streak.currentStreakCount > 0) {
        streak.streakHistory.push({
          startDate: streak.currentStreakStart,
          endDate: streak.currentStreakEnd,
          count: streak.currentStreakCount,
          endReason: 'missed',
        })
      }
      streak.currentStreakStart = date
      streak.currentStreakEnd = date
      streak.currentStreakCount = 1
    }

    streak.totalDaysTracked += 1
    streak.totalCompletedDays += 1
    streak.completionRate = Math.round((streak.totalCompletedDays / streak.totalDaysTracked) * 100)
    streak.lastCompletedDate = date
    streak.lastUpdated = new Date()

    if (streak.currentStreakCount > streak.bestStreakCount) {
      streak.bestStreakCount = streak.currentStreakCount
      streak.bestStreakStart = streak.currentStreakStart
      streak.bestStreakEnd = date
    }

    const lastHistory = streak.streakHistory[streak.streakHistory.length - 1]
    if (lastHistory && lastHistory.endReason === 'ongoing') {
      lastHistory.count = streak.currentStreakCount
      lastHistory.endDate = date
    } else if (continuesStreak && streak.currentStreakCount === 1) {
      streak.streakHistory.push({
        startDate: date,
        endDate: date,
        count: 1,
        endReason: 'ongoing',
      })
    }

    await streak.save()

    // Sync current streak count back to Habit document
    await Habit.findByIdAndUpdate(habitId, {
      currentStreak: streak.currentStreakCount,
      bestStreak: Math.max(streak.bestStreakCount, streak.currentStreakCount),
    })

    await deleteCache(CACHE_KEYS.habitStreak(userId, habitId))

    const MILESTONES = [7, 14, 30, 50, 100]
    if (MILESTONES.includes(streak.currentStreakCount)) {
      emitToUser(userId, SOCKET_EVENTS.STREAK_MILESTONE, {
        habitId,
        days: streak.currentStreakCount,
      })
      await enqueueAchievementCheck(userId, `streak_${streak.currentStreakCount}`)
    }
  },

  // ── Handle habit uncomplete ──────────────────────────────────────
  handleHabitUncomplete: async (userId, habitId, date) => {
    const streak = await Streak.findOne({ userId, habitId })
    if (!streak) return

    if (streak.currentStreakEnd === date && streak.currentStreakCount > 0) {
      streak.currentStreakCount = Math.max(0, streak.currentStreakCount - 1)
      streak.currentStreakEnd = getPreviousDate(date)
      if (streak.currentStreakCount === 0) streak.currentStreakStart = null
      streak.lastUpdated = new Date()
      await streak.save()
      await Habit.findByIdAndUpdate(habitId, {
        currentStreak: streak.currentStreakCount,
      })
      await deleteCache(CACHE_KEYS.habitStreak(userId, habitId))
    }
  },

  // ── Handle productive day (overall streak) ───────────────────────
  handleProductiveDay: async (userId, date) => {
    let streak = await Streak.findOne({ userId, habitId: null })
    if (!streak) streak = new Streak({ userId, habitId: null })

    const yesterday = getPreviousDate(date)
    const yesterdayLog = await DayLog.findOne({ userId, date: yesterday }).lean()
    const yesterdayWasGood =
      yesterdayLog?.isProductiveDay || yesterdayLog?.isFreezeDay || yesterdayLog?.isCheatDay

    const continuesStreak = yesterdayWasGood || streak.currentStreakCount === 0

    if (continuesStreak) {
      if (!streak.currentStreakStart) streak.currentStreakStart = date
      streak.currentStreakEnd = date
      streak.currentStreakCount += 1
    } else {
      if (streak.currentStreakCount > 0) {
        streak.streakHistory.push({
          startDate: streak.currentStreakStart,
          endDate: streak.currentStreakEnd,
          count: streak.currentStreakCount,
          endReason: 'missed',
        })
      }
      streak.currentStreakStart = date
      streak.currentStreakEnd = date
      streak.currentStreakCount = 1
    }

    if (streak.currentStreakCount > streak.bestStreakCount) {
      streak.bestStreakCount = streak.currentStreakCount
      streak.bestStreakStart = streak.currentStreakStart
      streak.bestStreakEnd = date
    }

    streak.totalDaysTracked += 1
    streak.totalCompletedDays += 1
    streak.completionRate = Math.round((streak.totalCompletedDays / streak.totalDaysTracked) * 100)
    streak.lastUpdated = new Date()
    await streak.save()

    // Sync to User document for fast access
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        currentStreakDays: streak.currentStreakCount,
        bestStreakDays: Math.max(streak.bestStreakCount, streak.currentStreakCount),
        lastProductiveDate: date,
      },
      { new: true }
    ).select('currentStreakDays bestStreakDays level xpPoints xpToNextLevel').lean()

    await deleteCache(CACHE_KEYS.userStreak(userId))
    await deleteCache(CACHE_KEYS.userProfile(userId))

    // ── Real-time: emit streak update to Flutter ──────────────────
    emitToUser(userId, SOCKET_EVENTS.STREAK_UPDATED, {
      currentStreakDays: streak.currentStreakCount,
      bestStreakDays: updatedUser?.bestStreakDays ?? streak.bestStreakCount,
      date,
    })

    // Milestone check
    const MILESTONES = [7, 14, 30, 50, 100, 365]
    if (MILESTONES.includes(streak.currentStreakCount)) {
      emitToUser(userId, SOCKET_EVENTS.STREAK_MILESTONE, {
        days: streak.currentStreakCount,
        label: getMilestoneLabel(streak.currentStreakCount),
      })
      await enqueueAchievementCheck(userId, `streak_${streak.currentStreakCount}`)
    }
  },

  // ── Full recalculate (used after freeze/cheat day) ───────────────
  // Walks ALL DayLog records and correctly handles gaps (missed days
  // with no DayLog entry reset the streak to 0)
  recalculate: async (userId) => {
    const logs = await DayLog.find({ userId })
      .sort({ date: 1 })
      .select('date isProductiveDay isFreezeDay isCheatDay')
      .lean()

    let currentStreak = 0
    let bestStreak = 0
    let streakStart = null
    let prevDate = null

    for (const log of logs) {
      const isGoodDay = log.isProductiveDay || log.isFreezeDay || log.isCheatDay

      if (!isGoodDay) {
        // Bad day in DayLog — reset streak
        if (currentStreak > bestStreak) bestStreak = currentStreak
        currentStreak = 0
        streakStart = null
        prevDate = null
        continue
      }

      if (prevDate) {
        const gap = daysBetween(prevDate, log.date)
        if (gap === 1) {
          // Consecutive day — extend streak
          currentStreak += 1
        } else {
          // Gap > 1 day — missed days in between, reset
          if (currentStreak > bestStreak) bestStreak = currentStreak
          currentStreak = 1
          streakStart = log.date
        }
      } else {
        currentStreak = 1
        streakStart = log.date
      }

      if (currentStreak > bestStreak) bestStreak = currentStreak
      prevDate = log.date
    }

    // ── Check if streak should be 0 today ────────────────────────
    // If the last good day was more than 1 day ago (with no DayLog
    // entries bridging the gap), reset to 0
    if (prevDate) {
      const today = getTodayDate()
      const gapFromLastGoodDay = daysBetween(prevDate, today)
      if (gapFromLastGoodDay > 1) {
        // There are unlogged missed days between last good day and today
        currentStreak = 0
        streakStart = null
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        currentStreakDays: currentStreak,
        bestStreakDays: bestStreak,
      },
      { new: true }
    ).select('currentStreakDays bestStreakDays').lean()

    await Streak.findOneAndUpdate(
      { userId, habitId: null },
      {
        currentStreakCount: currentStreak,
        currentStreakStart: streakStart,
        bestStreakCount: bestStreak,
        lastUpdated: new Date(),
      },
      { upsert: true }
    )

    await deleteCache(CACHE_KEYS.userStreak(userId))
    await deleteCache(CACHE_KEYS.userProfile(userId))

    // ── Real-time: emit updated streak to Flutter ─────────────────
    emitToUser(userId, SOCKET_EVENTS.STREAK_UPDATED, {
      currentStreakDays: currentStreak,
      bestStreakDays: updatedUser?.bestStreakDays ?? bestStreak,
    })
  },
}

const getMilestoneLabel = (days) => {
  const labels = {
    3: 'Getting Started 🌱',
    7: 'One Week Strong 🔥',
    14: 'Two Week Warrior ⚡',
    21: 'Habit Forming 🧠',
    30: '30 Day Legend 🏆',
    50: 'Fifty and Fierce 💪',
    75: 'Unstoppable 🚀',
    100: '100 Day Champion 👑',
    150: 'Elite Performer 🌟',
    200: 'Almost 365 👀',
    365: 'One Full Year 🎯',
  }
  return labels[days] || `${days} Days`
}