import { User } from '../models/index.js'
import { deleteCache, CACHE_KEYS } from '../config/redis.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'
import { notificationService } from './notification.service.js'

// ─── XP thresholds per level ─────────────────────────────────────────────────
// Level N requires XP_TABLE[N-1] total XP to reach
const XP_TABLE = [
  0,    // Level 1  — start
  100,  // Level 2
  250,  // Level 3
  450,  // Level 4
  700,  // Level 5
  1000, // Level 6
  1400, // Level 7
  1900, // Level 8
  2500, // Level 9
  3200, // Level 10
  4000, // Level 11
  5000, // Level 12
  6200, // Level 13
  7600, // Level 14
  9200, // Level 15
  11000,// Level 16
  13000,// Level 17
  15500,// Level 18
  18500,// Level 19
  22000,// Level 20 — max visible level
]

// ─── XP rewards ──────────────────────────────────────────────────────────────
export const XP_REWARDS = {
  productive_day: 50,
  habit_complete: 10,
  streak_7: 100,
  streak_14: 150,
  streak_30: 300,
  streak_50: 500,
  streak_100: 1000,
  achievement: 50,     // base — overridden per achievement
  friend_added: 20,
  perfect_week: 200,
}

export const gamificationService = {
  // ── Get level info ───────────────────────────────────────────────
  getLevel: async (userId) => {
    const user = await User.findById(userId)
      .select('level xpPoints xpToNextLevel')
      .lean()
    if (!user) throwNotFound('User')

    const currentThreshold = XP_TABLE[user.level - 1] || 0
    const nextThreshold = XP_TABLE[user.level] || XP_TABLE[XP_TABLE.length - 1]

    return {
      level: user.level,
      xpPoints: user.xpPoints,
      xpToNextLevel: nextThreshold - user.xpPoints,
      xpCurrentLevel: user.xpPoints - currentThreshold,
      xpNeededForNextLevel: nextThreshold - currentThreshold,
      progressPercent: Math.round(
        ((user.xpPoints - currentThreshold) / (nextThreshold - currentThreshold)) * 100
      ),
      isMaxLevel: user.level >= XP_TABLE.length,
    }
  },

  // ── Get XP history ───────────────────────────────────────────────
  // We store XP events in Redis as a simple list for the feed
  getXPHistory: async (userId, { page, limit }) => {
    const { redis } = await import('../config/redis.js')
    const key = `xp_history:${userId}`
    const skip = (Number(page) - 1) * Number(limit)
    const raw = await redis.lrange(key, skip, skip + Number(limit) - 1)
    const total = await redis.llen(key)
    return {
      history: raw.map((r) => JSON.parse(r)),
      total,
      page: Number(page),
      limit: Number(limit),
    }
  },

  // ── Get badges ───────────────────────────────────────────────────
  getBadges: async (userId) => {
    const { UserAchievement } = await import('../models/index.js')
    return UserAchievement.find({ userId })
      .populate('achievementId', 'name icon badgeColor type')
      .sort({ unlockedAt: -1 })
      .lean()
  },

  // ── Award XP ─────────────────────────────────────────────────────
  // Core method — called by streak, habit, achievement services
  awardXP: async (userId, amount, reason) => {
    const user = await User.findById(userId).select('level xpPoints').lean()
    if (!user) return

    const newXP = user.xpPoints + amount
    const newLevel = calculateLevel(newXP)
    const leveledUp = newLevel > user.level

    await User.findByIdAndUpdate(userId, {
      xpPoints: newXP,
      level: newLevel,
      xpToNextLevel: getXPToNextLevel(newXP, newLevel),
    })

    await deleteCache(CACHE_KEYS.userProfile(userId))

    // Push to XP history in Redis (keep last 100 events)
    const { redis } = await import('../config/redis.js')
    const key = `xp_history:${userId}`
    await redis.lpush(key, JSON.stringify({
      amount,
      reason,
      total: newXP,
      timestamp: new Date().toISOString(),
    }))
    await redis.ltrim(key, 0, 99) // keep last 100
    // Level-up notification + socket
    // Always emit XP earned
    emitToUser(userId, SOCKET_EVENTS.XP_EARNED, {
      amount,
      reason,
      total: newXP,
      level: newLevel,
    })

    // Level-up notification + socket
    if (leveledUp) {
      await notificationService.sendToUser(userId, {
        type: 'level_up',
        title: `Level Up! 🎉`,
        body: `You reached Level ${newLevel}! Keep going 🚀`,
        deepLinkScreen: 'Profile',
      })

      emitToUser(userId, SOCKET_EVENTS.LEVEL_UP, {   // ← was STREAK_MILESTONE, wrong event
        newLevel,
        xpPoints: newXP,
      })
    }

    return { xpPoints: newXP, level: newLevel, leveledUp }
  },

  // ── Award XP for productive day ──────────────────────────────────
  // Called by dayLog service when isProductiveDay = true
  awardProductiveDay: async (userId) => {
    return gamificationService.awardXP(userId, XP_REWARDS.productive_day, 'productive_day')
  },

  // ── Award XP for habit completion ────────────────────────────────
  awardHabitComplete: async (userId, habitId) => {
    return gamificationService.awardXP(userId, XP_REWARDS.habit_complete, `habit_complete:${habitId}`)
  },
}

// ─── Calculate level from total XP ──────────────────────────────────────────
const calculateLevel = (xp) => {
  let level = 1
  for (let i = 0; i < XP_TABLE.length; i++) {
    if (xp >= XP_TABLE[i]) level = i + 1
    else break
  }
  return Math.min(level, XP_TABLE.length)
}

// ─── Get XP needed for next level ───────────────────────────────────────────
const getXPToNextLevel = (xp, currentLevel) => {
  const nextThreshold = XP_TABLE[currentLevel] || XP_TABLE[XP_TABLE.length - 1]
  return Math.max(0, nextThreshold - xp)
}

const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}