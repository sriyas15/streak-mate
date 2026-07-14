import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { notificationService } from './notification.service.js'
import { freezeService } from './freeze.service.js'
import { streakService } from './streak.service.js'
import { dayLogService } from './dayLog.service.js'
import { gamificationService } from './gamification.service.js'
import { achievementService } from './achievement.service.js'
import { User, Habit, DayLog, Streak } from '../models/index.js'
import { getTodayDate } from '../utils/dateHelper.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'

// ─── Worker factory ──────────────────────────────────────────────────────────
const createWorker = (queueName, processor) => {
  const worker = new Worker(queueName, processor, {
    connection: redis,
    concurrency: 5,
  })

  worker.on('completed', (job) => {
    console.log(`✅ [${queueName}] Job ${job.id} completed`)
  })
  worker.on('failed', (job, err) => {
    console.error(`❌ [${queueName}] Job ${job?.id} failed: ${err.message}`)
  })

  return worker
}

// ─── Workers ─────────────────────────────────────────────────────────────────

/**
 * Habit Reminder Worker
 * Sends per-habit reminders at scheduled times
 * Job data: { userId, habitId, habitName, time }
 */
export const habitReminderWorker = createWorker(
  QUEUE_NAMES.HABIT_REMINDER,
  async (job) => {
    const { userId, habitId, habitName } = job.data

    const today = getTodayDate()
    const { HabitLog } = await import('../models/index.js')
    const log = await HabitLog.findOne({ userId, habitId, date: today, isCompleted: true })
    if (log) return

    await notificationService.sendFromTemplate(userId, 'habit_reminder', {
      habitName,
    })
  }
)

/**
 * Streak Warning Worker
 * Runs at 9PM — warns users who haven't completed all habits
 */
export const streakWarningWorker = createWorker(
  QUEUE_NAMES.STREAK_WARNING,
  async () => {
    const today = getTodayDate()

    const usersAtRisk = await User.find({
      isActive: true,
      isDeleted: false,
      currentStreakDays: { $gt: 0 },
      notificationsEnabled: true,
    })
      .select('_id name currentStreakDays')
      .lean()

    for (const user of usersAtRisk) {
      const dayLog = await DayLog.findOne({ userId: user._id, date: today })
      if (dayLog?.isProductiveDay || dayLog?.isFreezeDay || dayLog?.isCheatDay) continue

      await notificationService.sendFromTemplate(String(user._id), 'streak_at_risk', {
        userName: user.name,
        streakCount: String(user.currentStreakDays),
      })
    }
  }
)

/**
 * End of Day Worker
 * Runs at midnight — resolves all incomplete days, breaks streaks where needed
 */
export const endOfDayWorker = createWorker(
  QUEUE_NAMES.END_OF_DAY,
  async () => {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = yesterday.toISOString().split('T')[0]

    const users = await User.find({
      isActive: true,
      isDeleted: false,
    }).select('_id name currentStreakDays bestStreakDays').lean()

    for (const user of users) {
      // ── Finalise yesterday's daylog ────────────────────────────
      // DO NOT upsert — only update if a real DayLog exists.
      // Upserting creates blank docs for users with no activity,
      // which would incorrectly trigger streak breaks.
      const dayLog = await DayLog.findOneAndUpdate(
        { userId: user._id, date: yesterdayStr, resolvedAt: null },
        { resolvedAt: new Date() },
        { new: true }
      ) ?? { isProductiveDay: false, isFreezeDay: false, isCheatDay: false }

      // ── Award XP for productive day ────────────────────────────
      if (dayLog.isProductiveDay) {
        await gamificationService.awardProductiveDay(String(user._id))
        await achievementService.checkAndUnlock(String(user._id), 'streak')
      }

      // ── Streak broken ──────────────────────────────────────────
      // Only break streak if yesterday was not productive/protected
      // AND user actually had an active streak
      if (
        !dayLog.isProductiveDay &&
        !dayLog.isFreezeDay &&
        !dayLog.isCheatDay &&
        user.currentStreakDays > 0
      ) {
        // Notify user
        await notificationService.sendFromTemplate(String(user._id), 'streak_broken', {
          streakCount: String(user.currentStreakDays),
        })

        // Reset User document streak
        await User.findByIdAndUpdate(user._id, {
          currentStreakDays: 0,
          lastProductiveDate: null,
        })

        // Reset Streak document so handleProductiveDay doesn't
        // pick up the old count next time user completes a habit
        await Streak.findOneAndUpdate(
          { userId: user._id, habitId: null },
          {
            currentStreakCount: 0,
            currentStreakStart: null,
            currentStreakEnd: null,
            lastUpdated: new Date(),
          }
        )

        // Real-time: push streak reset to Flutter immediately
        emitToUser(String(user._id), SOCKET_EVENTS.STREAK_UPDATED, {
          currentStreakDays: 0,
          bestStreakDays: user.bestStreakDays ?? 0,
        })

        console.log(`🔥 Streak broken for user ${user._id} (was ${user.currentStreakDays} days)`)
      }
    }

    // ── Reset monthly freeze allowances on 1st of month ──────────
    const today = getTodayDate()
    if (today.endsWith('-01')) {
      await freezeService.resetMonthlyAllowances()
    }
  }
)

/**
 * Weekly Report Worker
 * Runs every Sunday at 8PM
 */
export const weeklyReportWorker = createWorker(
  QUEUE_NAMES.WEEKLY_REPORT,
  async () => {
    const users = await User.find({
      isActive: true,
      isDeleted: false,
      notificationsEnabled: true,
    }).select('_id name currentStreakDays').lean()

    for (const user of users) {
      await notificationService.sendFromTemplate(String(user._id), 'weekly_summary', {
        userName: user.name,
        streakCount: String(user.currentStreakDays),
      })
    }
  }
)

/**
 * Monthly Report Worker
 * Runs on 1st of every month at 9AM
 */
export const monthlyReportWorker = createWorker(
  QUEUE_NAMES.MONTHLY_REPORT,
  async () => {
    const users = await User.find({
      isActive: true,
      isDeleted: false,
      notificationsEnabled: true,
    }).select('_id name').lean()

    for (const user of users) {
      await notificationService.sendFromTemplate(String(user._id), 'monthly_report', {
        userName: user.name,
      })
    }
  }
)

/**
 * Funny Notification Worker
 * Runs daily at 11AM — sends engagement notifications to inactive users
 */
export const funnyNotifWorker = createWorker(
  QUEUE_NAMES.FUNNY_NOTIF,
  async () => {
    const today = getTodayDate()

    const activeToday = await DayLog.find({
      date: today,
      completedHabits: { $gt: 0 },
    }).distinct('userId')

    const inactiveUsers = await User.find({
      isActive: true,
      isDeleted: false,
      notificationsEnabled: true,
      _id: { $nin: activeToday },
    }).select('_id name currentStreakDays').lean()

    for (const user of inactiveUsers) {
      const type = user.currentStreakDays > 0 ? 'funny_inactive' : 'funny_morning'
      await notificationService.sendFromTemplate(String(user._id), type, {
        userName: user.name,
        streakCount: String(user.currentStreakDays),
      })
    }
  }
)

/**
 * Push Notification Delivery Worker
 * Final delivery queue — actually sends FCM
 */
export const pushNotificationWorker = createWorker(
  QUEUE_NAMES.PUSH_NOTIFICATION,
  async (job) => {
    const { userId, type, title, body, data, habitId } = job.data
    await notificationService.sendToUser(userId, { type, title, body, data, habitId })
  }
)

/**
 * Achievement Check Worker
 * Triggered after habit complete / streak milestone
 */
export const achievementCheckWorker = createWorker(
  QUEUE_NAMES.ACHIEVEMENT_CHECK,
  async (job) => {
    const { userId, trigger } = job.data
    await achievementService.checkAndUnlock(userId, trigger)
  }
)

// ─── Graceful shutdown for all workers ──────────────────────────────────────
export const closeWorkers = async () => {
  await Promise.all([
    habitReminderWorker.close(),
    streakWarningWorker.close(),
    endOfDayWorker.close(),
    weeklyReportWorker.close(),
    monthlyReportWorker.close(),
    funnyNotifWorker.close(),
    pushNotificationWorker.close(),
    achievementCheckWorker.close(),
  ])
  console.log('🔌 All BullMQ workers closed')
}