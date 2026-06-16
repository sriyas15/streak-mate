import { Achievement, UserAchievement, User, Streak } from '../models/index.js'
import { notificationService } from './notification.service.js'
import { gamificationService } from './gamification.service.js'
import { emitToUser, SOCKET_EVENTS } from '../config/socket.js'

// ─── Achievement condition checkers ──────────────────────────────────────────
const CONDITION_CHECKERS = {
  streak_3: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 3
  },
  streak_7: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 7
  },
  streak_14: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 14
  },
  streak_21: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 21
  },
  streak_30: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 30
  },
  streak_50: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 50
  },
  streak_100: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 100
  },
  streak_365: async (userId) => {
    const user = await User.findById(userId).select('currentStreakDays').lean()
    return user.currentStreakDays >= 365
  },
  first_habit_complete: async (userId) => {
    const { HabitLog } = await import('../models/index.js')
    const count = await HabitLog.countDocuments({ userId, isCompleted: true })
    return count >= 1
  },
  perfect_week: async (userId) => {
    const { DayLog } = await import('../models/index.js')
    const { getWeekRange } = await import('../utils/dateHelper.js')
    const { from, to } = getWeekRange()
    const logs = await DayLog.find({ userId, date: { $gte: from, $lte: to } }).lean()
    return logs.length === 7 && logs.every((l) => l.isProductiveDay)
  },
  add_5_friends: async (userId) => {
    const user = await User.findById(userId).select('friendIds').lean()
    return user.friendIds.length >= 5
  },
  nudge_sent: async () => true, // triggered directly on nudge action
}

export const achievementService = {
  // ── Get all achievements with unlock status ──────────────────────
  getAllAchievements: async (userId) => {
    const [all, unlocked] = await Promise.all([
      Achievement.find({ isActive: true }).sort({ displayOrder: 1 }).lean(),
      UserAchievement.find({ userId }).select('achievementId unlockedAt').lean(),
    ])

    const unlockedMap = {}
    for (const ua of unlocked) {
      unlockedMap[String(ua.achievementId)] = ua.unlockedAt
    }

    return all.map((a) => ({
      ...a,
      isUnlocked: !!unlockedMap[String(a._id)],
      unlockedAt: unlockedMap[String(a._id)] || null,
    }))
  },

  // ── Get unlocked achievements ────────────────────────────────────
  getUnlocked: async (userId) => {
    return UserAchievement.find({ userId })
      .populate('achievementId')
      .sort({ unlockedAt: -1 })
      .lean()
  },

  // ── Get locked achievements ──────────────────────────────────────
  getLocked: async (userId) => {
    const unlocked = await UserAchievement.find({ userId }).select('achievementId').lean()
    const unlockedIds = unlocked.map((u) => u.achievementId)

    return Achievement.find({
      _id: { $nin: unlockedIds },
      isActive: true,
    }).sort({ displayOrder: 1 }).lean()
  },

  // ── Get 5 most recent unlocks ─────────────────────────────────────
  getRecent: async (userId) => {
    return UserAchievement.find({ userId })
      .populate('achievementId')
      .sort({ unlockedAt: -1 })
      .limit(5)
      .lean()
  },

  // ── Mark achievement as seen ─────────────────────────────────────
  markSeen: async (userId, achievementId) => {
    await UserAchievement.findOneAndUpdate(
      { userId, achievementId },
      { seen: true }
    )
  },

  // ── Check and unlock achievements ────────────────────────────────
  // Called by BullMQ achievementCheckJob with a trigger context
  checkAndUnlock: async (userId, trigger) => {
    // Find achievements matching this trigger
    const achievements = await Achievement.find({
      isActive: true,
      condition: { $regex: trigger },
    }).lean()

    for (const achievement of achievements) {
      // Skip already unlocked
      const alreadyUnlocked = await UserAchievement.findOne({
        userId,
        achievementId: achievement._id,
      })
      if (alreadyUnlocked) continue

      // Run condition checker
      const checker = CONDITION_CHECKERS[achievement.condition]
      if (!checker) continue

      const passed = await checker(userId)
      if (!passed) continue

      // Unlock it
      await UserAchievement.create({
        userId,
        achievementId: achievement._id,
        unlockedAt: new Date(),
        seen: false,
      })

      // Award XP
      if (achievement.xpReward > 0) {
        await gamificationService.awardXP(userId, achievement.xpReward, `achievement:${achievement.condition}`)
      }

      // Send notification
      await notificationService.sendToUser(userId, {
        type: 'achievement_unlocked',
        title: `Achievement Unlocked 🏆`,
        body: `${achievement.icon} ${achievement.name} — ${achievement.description}`,
        deepLinkScreen: 'Achievements',
        deepLinkParams: { achievementId: achievement._id },
      })

      // Socket emit for instant in-app animation
      emitToUser(userId, SOCKET_EVENTS.STREAK_MILESTONE, {
        type: 'achievement',
        achievement,
      })
    }
  },
}