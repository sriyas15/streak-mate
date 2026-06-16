import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { User, DayLog, HabitLog, Habit } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'
import { getTodayDate } from '../utils/dateHelper.js'

/**
 * Streak Warning Job
 * Runs at 9:00 PM every day via BullMQ cron
 *
 * Logic:
 * - Find users with currentStreak > 0 and notificationsEnabled
 * - Check if today is already resolved as productive / frozen / cheat
 * - If not — send "streak at risk" warning
 * - Calculate time remaining for urgency level in message
 */
export const streakWarningWorker = new Worker(
  QUEUE_NAMES.STREAK_WARNING,
  async (job) => {
    console.log('🔥 Running streak warning job...')
    const today = getTodayDate()
    const dayOfWeek = new Date().getDay()

    // Users with active streaks and notifications on
    const usersAtRisk = await User.find({
      isActive: true,
      isDeleted: false,
      currentStreakDays: { $gt: 0 },
      notificationsEnabled: true,
    })
      .select('_id name currentStreakDays')
      .lean()

    let warned = 0
    let skipped = 0

    for (const user of usersAtRisk) {
      const userId = user._id.toString()

      // Check if today's day log already has a good resolution
      const dayLog = await DayLog.findOne({ userId, date: today })
      if (dayLog?.isProductiveDay || dayLog?.isFreezeDay || dayLog?.isCheatDay) {
        skipped++
        continue
      }

      // Check if user has any habits scheduled for today
      const habitsToday = await Habit.findOne({
        userId,
        isActive: true,
        isArchived: false,
        activeDays: dayOfWeek,
      })
      if (!habitsToday) {
        skipped++ // no habits today — streak not at risk
        continue
      }

      // Count remaining incomplete habits
      const habits = await Habit.find({
        userId,
        isActive: true,
        isArchived: false,
        activeDays: dayOfWeek,
      })
        .select('_id')
        .lean()

      const habitIds = habits.map((h) => h._id)
      const completedCount = await HabitLog.countDocuments({
        userId,
        habitId: { $in: habitIds },
        date: today,
        isCompleted: true,
      })

      const remaining = habits.length - completedCount

      // Vary message based on urgency
      const notifType = remaining === 0 ? 'streak_warning' : 'streak_at_risk'

      await notificationService.sendFromTemplate(userId, notifType, {
        userName: user.name,
        streakCount: String(user.currentStreakDays),
        remaining: String(remaining),
      })

      warned++
    }

    console.log(`✅ Streak warning job done — warned: ${warned}, skipped: ${skipped}`)
  },
  {
    connection: redis,
    concurrency: 3,
  }
)

streakWarningWorker.on('failed', (job, err) => {
  console.error(`❌ [streakWarningJob] failed: ${err.message}`)
})