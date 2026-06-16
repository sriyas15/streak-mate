import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { User, DayLog, HabitLog, Habit, Streak } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'

/**
 * Monthly Report Job
 * Runs on 1st of every month at 9:00 AM
 *
 * Sends each user their previous month summary:
 * - Productive days
 * - Best streak achieved
 * - Most completed habit
 * - Success rate
 */
export const monthlyReportWorker = new Worker(
  QUEUE_NAMES.MONTHLY_REPORT,
  async (job) => {
    console.log('📅 Running monthly report job...')

    // Calculate previous month range
    const now = new Date()
    const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
    const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0)
    const from = prevMonth.toISOString().split('T')[0]
    const to = prevMonthEnd.toISOString().split('T')[0]
    const monthLabel = prevMonth.toLocaleString('default', { month: 'long', year: 'numeric' })

    const users = await User.find({
      isActive: true,
      isDeleted: false,
      notificationsEnabled: true,
    })
      .select('_id name bestStreakDays')
      .lean()

    let sent = 0

    for (const user of users) {
      const userId = user._id.toString()

      try {
        const dayLogs = await DayLog.find({
          userId,
          date: { $gte: from, $lte: to },
          resolvedAt: { $ne: null },
        }).lean()

        if (dayLogs.length === 0) continue

        const productiveDays = dayLogs.filter((d) => d.isProductiveDay).length
        const totalDays = dayLogs.length
        const successRate = Math.round((productiveDays / totalDays) * 100)

        // Best streak this month from streak history
        const overallStreak = await Streak.findOne({ userId, habitId: null }).lean()
        const bestStreakThisMonth = overallStreak?.streakHistory
          ?.filter((s) => s.startDate >= from && s.startDate <= to)
          ?.reduce((max, s) => Math.max(max, s.count), 0) || 0

        // Most completed habit
        const habits = await Habit.find({ userId, isActive: true }).select('_id name').lean()
        const habitIds = habits.map((h) => h._id)

        const topHabitAgg = await HabitLog.aggregate([
          { $match: { userId: user._id, habitId: { $in: habitIds }, date: { $gte: from, $lte: to }, isCompleted: true } },
          { $group: { _id: '$habitId', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 1 },
        ])

        const topHabit = habits.find(
          (h) => h._id.toString() === topHabitAgg[0]?._id?.toString()
        )

        await notificationService.sendFromTemplate(userId, 'monthly_report', {
          userName: user.name,
          monthLabel,
          productiveDays: String(productiveDays),
          totalDays: String(totalDays),
          successRate: String(successRate),
          bestStreak: String(bestStreakThisMonth),
          topHabitName: topHabit?.name || 'your habits',
        })

        sent++
      } catch (err) {
        console.error(`❌ monthlyReport failed for ${userId}: ${err.message}`)
      }
    }

    console.log(`✅ Monthly report done — sent to ${sent} users`)
  },
  {
    connection: redis,
    concurrency: 3,
  }
)

monthlyReportWorker.on('failed', (job, err) => {
  console.error(`❌ [monthlyReportJob] failed: ${err.message}`)
})