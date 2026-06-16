import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { User, DayLog, HabitLog, Habit } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'
import { getTodayDate } from '../utils/dateHelper.js'

/**
 * Funny Notification Job — Swiggy/Zomato style engagement
 * Runs every day at 11:00 AM
 *
 * Segments users into buckets and sends the right funny message:
 *
 * BUCKET A — Completed everything already → funny_perfect_day
 * BUCKET B — In progress (some done) → funny_almost_done
 * BUCKET C — Haven't opened app / done nothing → funny_inactive
 * BUCKET D — Morning (streak = 0) → funny_morning
 * BUCKET E — User had junk food habit incomplete → funny_relapse
 */

// Funny notification copy — these complement NotificationTemplate variants
const FUNNY_COPY = {
  funny_perfect_day: [
    "ALL habits done at 11AM?! Who are you and what have you done with the average person 🐐",
    "You finished everything already. The rest of us are still in bed. Legendary. 👑",
    "Done by 11AM. Your habits didn't stand a chance. Neither did excuses. 🔥",
  ],
  funny_almost_done: [
    "You're SO close. 2 habits left. Your streak is literally begging you. 🙏",
    "Almost there! Your future self is watching. Don't let them down 👀",
    "The finish line is RIGHT there. Don't ghost your habits now 😤",
  ],
  funny_inactive: [
    "Bro. It's 11AM. Your habits are sitting there. Lonely. Judging you. 😢",
    "Your streak called. It said it misses you. Also it's scared 🔥😰",
    "We checked — you haven't logged anything. We're not mad. Just disappointed. 💔",
    "Your habits won't do themselves. We checked. Twice. 📋",
  ],
  funny_morning: [
    "New day, new chance to not be the person who quits 💪",
    "Good morning! Your habits are up. Are you? ☀️",
    "The day is young. Your excuses are old. Let's go 🚀",
  ],
  funny_relapse: [
    "Your diet habit is crying in the corner rn 🥲 But today is a new day!",
    "Yesterday happened. Today doesn't have to. Your streak forgives you. 😤",
    "Junk food: 1. You: 0. Today we reset the score 🔄",
  ],
}

const pickRandom = (arr) => arr[Math.floor(Math.random() * arr.length)]

export const funnyNotifWorker = new Worker(
  QUEUE_NAMES.FUNNY_NOTIF,
  async (job) => {
    console.log('😄 Running funny notification job...')
    const today = getTodayDate()
    const dayOfWeek = new Date().getDay()

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
        // Get today's habits for this user
        const habits = await Habit.find({
          userId,
          isActive: true,
          isArchived: false,
          activeDays: dayOfWeek,
        })
          .select('_id category')
          .lean()

        if (habits.length === 0) continue

        const habitIds = habits.map((h) => h._id)
        const logs = await HabitLog.find({
          userId,
          habitId: { $in: habitIds },
          date: today,
        }).lean()

        const completedCount = logs.filter((l) => l.isCompleted).length
        const totalCount = habits.length
        const hasAnyActivity = logs.length > 0

        // Segment into bucket
        let type
        let title
        let body

        if (completedCount === totalCount) {
          // All done
          type = 'funny_perfect_day'
          title = '🐐 You absolute legend'
          body = pickRandom(FUNNY_COPY.funny_perfect_day)
        } else if (completedCount > 0 && totalCount - completedCount <= 2) {
          // Almost done
          type = 'funny_almost_done'
          title = `🎯 ${totalCount - completedCount} habit${totalCount - completedCount > 1 ? 's' : ''} left`
          body = pickRandom(FUNNY_COPY.funny_almost_done)
        } else if (!hasAnyActivity && user.currentStreakDays > 0) {
          // Has streak but not started today
          type = 'funny_inactive'
          title = `🔥 Day ${user.currentStreakDays} streak in danger`
          body = pickRandom(FUNNY_COPY.funny_inactive)
        } else if (!hasAnyActivity && user.currentStreakDays === 0) {
          // No streak, hasn't started
          type = 'funny_morning'
          title = '☀️ Good morning, champion'
          body = pickRandom(FUNNY_COPY.funny_morning)
        } else {
          // In progress
          type = 'funny_almost_done'
          title = `💪 ${completedCount}/${totalCount} done`
          body = pickRandom(FUNNY_COPY.funny_almost_done)
        }

        await notificationService.sendToUser(userId, { type, title, body })
        sent++
      } catch (err) {
        console.error(`❌ funnyNotif failed for ${userId}: ${err.message}`)
      }
    }

    console.log(`✅ Funny notifications sent to ${sent} users`)
  },
  {
    connection: redis,
    concurrency: 5,
  }
)

funnyNotifWorker.on('failed', (job, err) => {
  console.error(`❌ [funnyNotifJob] failed: ${err.message}`)
})