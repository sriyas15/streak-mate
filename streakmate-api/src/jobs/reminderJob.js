import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES, queues } from '../config/bullmq.js'
import { Habit, User } from '../models/index.js'
import { HabitLog } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'
import { getTodayDate } from '../utils/dateHelper.js'

/**
 * Reminder Job
 *
 * Two responsibilities:
 * 1. SCHEDULER — runs every hour, scans habits whose reminderTimes
 *    match the current hour and enqueues per-habit reminder jobs
 *
 * 2. WORKER — processes individual reminder jobs for a single user+habit
 */

// ─── Scheduler: runs every hour, enqueues individual reminder jobs ────────────
export const scheduleHabitReminders = async () => {
  const now = new Date()
  const currentTime = `${String(now.getHours()).padStart(2, '0')}:00`
  const today = getTodayDate()
  const dayOfWeek = now.getDay()

  // Find all habits with a reminder at this hour, on this day
  const habits = await Habit.find({
    isActive: true,
    isArchived: false,
    reminderEnabled: true,
    reminderTimes: currentTime,
    activeDays: dayOfWeek,
    reminderDays: dayOfWeek,
  })
    .select('_id userId name reminderTimes')
    .lean()

  if (habits.length === 0) return

  // Filter out habits already completed today
  const habitIds = habits.map((h) => h._id)
  const completedToday = await HabitLog.find({
    habitId: { $in: habitIds },
    date: today,
    isCompleted: true,
  })
    .select('habitId')
    .lean()

  const completedIds = new Set(completedToday.map((l) => l.habitId.toString()))

  const toNotify = habits.filter((h) => !completedIds.has(h._id.toString()))

  // Enqueue individual reminder jobs
  const jobs = toNotify.map((habit) => ({
    name: 'habit-reminder',
    data: {
      userId: habit.userId.toString(),
      habitId: habit._id.toString(),
      habitName: habit.name,
      scheduledTime: currentTime,
    },
  }))

  if (jobs.length > 0) {
    await queues.habitReminder.addBulk(jobs)
    console.log(`📅 Enqueued ${jobs.length} habit reminders for ${currentTime}`)
  }
}

// ─── Worker: processes individual reminder job ────────────────────────────────
export const reminderWorker = new Worker(
  QUEUE_NAMES.HABIT_REMINDER,
  async (job) => {
    const { userId, habitId, habitName } = job.data
    const today = getTodayDate()

    // Double-check habit isn't completed between schedule and now
    const alreadyDone = await HabitLog.findOne({
      userId,
      habitId,
      date: today,
      isCompleted: true,
    })
    if (alreadyDone) {
      console.log(`⏭️  Skipping reminder — habit already done: ${habitName}`)
      return
    }

    // Check user notifications are still enabled
    const user = await User.findById(userId).select('notificationsEnabled name').lean()
    if (!user?.notificationsEnabled) return

    await notificationService.sendFromTemplate(userId, 'habit_reminder', {
      userName: user.name,
      habitName,
    })

    console.log(`🔔 Sent reminder: ${habitName} → ${userId}`)
  },
  {
    connection: redis,
    concurrency: 10,
  }
)

reminderWorker.on('completed', (job) => {
  console.log(`✅ [reminderJob] ${job.id} done`)
})

reminderWorker.on('failed', (job, err) => {
  console.error(`❌ [reminderJob] ${job?.id} failed: ${err.message}`)
})