import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { User, DayLog, HabitLog, Habit } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'
import { getWeekRange } from '../utils/dateHelper.js'

/**
 * Weekly Report Job
 * Runs every Sunday at 8:00 PM
 *
 * Sends each user a personalised weekly summary:
 * - Productive days this week
 * - Best performing habit
 * - Streak count
 * - Motivational message based on performance
 */
export const weeklyReportWorker = new Worker(
  QUEUE_NAMES.WEEKLY_REPORT,
  async (job) => {
    console.log('📊 Running weekly report job...')

    const { from, to } = getWeekRange()

    const users = await User.find({
      isActive: true,
      isDeleted: false,
      notificationsEnabled: true,
    })
      .select('_id name currentStreakDays')
      .lean()

    let sent = 0

    for (const user of users) {
      const userId = user._id.toString()

      try {
        // Get this week's day logs
        const dayLogs = await DayLog.find({
          userId,
          date: { $gte: from, $lte: to },
          resolvedAt: { $ne: null },
        }).lean()

        const productiveDays = dayLogs.filter((d) => d.isProductiveDay).length
        const totalDays = dayLogs.length

        if (totalDays === 0) continue // no data this week

        // Determine tone of message
        let tone = 'okay'
        if (productiveDays === 7) tone = 'perfect'
        else if (productiveDays >= 5) tone = 'great'
        else if (productiveDays >= 3) tone = 'good'
        else tone = 'needs_work'

        // Find best performing habit this week
        const habits = await Habit.find({ userId, isActive: true }).select('_id name icon').lean()
        const habitIds = habits.map((h) => h._id)

        const habitLogs = await HabitLog.find({
          userId,
          habitId: { $in: habitIds },
          date: { $gte: from, $lte: to },
          isCompleted: true,
        }).lean()

        const habitCompletionCount = {}
        for (const log of habitLogs) {
          const id = log.habitId.toString()
          habitCompletionCount[id] = (habitCompletionCount[id] || 0) + 1
        }

        const bestHabitId = Object.entries(habitCompletionCount).sort(
          ([, a], [, b]) => b - a
        )[0]?.[0]
        const bestHabit = habits.find((h) => h._id.toString() === bestHabitId)

        await notificationService.sendFromTemplate(userId, 'weekly_summary', {
          userName: user.name,
          productiveDays: String(productiveDays),
          totalDays: String(totalDays),
          streakCount: String(user.currentStreakDays),
          bestHabitName: bestHabit?.name || 'your habits',
          tone,
        })

        sent++
      } catch (err) {
        console.error(`❌ weeklyReport failed for ${userId}: ${err.message}`)
      }
    }

    console.log(`✅ Weekly report done — sent to ${sent} users`)
  },
  {
    connection: redis,
    concurrency: 3,
  }
)

weeklyReportWorker.on('failed', (job, err) => {
  console.error(`❌ [weeklyReportJob] failed: ${err.message}`)
})