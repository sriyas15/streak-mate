import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { User, DayLog, Habit, HabitLog } from '../models/index.js'
import { notificationService } from '../services/notification.service.js'
import { freezeService } from '../services/freeze.service.js'
import { gamificationService } from '../services/gamification.service.js'
import { achievementService } from '../services/achievement.service.js'
import { streakService } from '../services/streak.service.js'
import { deleteCache, CACHE_KEYS } from '../config/redis.js'

/**
 * End of Day Job
 * Runs at 00:00 (midnight) every day
 *
 * Processes yesterday for every user:
 * 1. Resolve DayLog (mark resolvedAt)
 * 2. If productive → award XP, check achievements
 * 3. If not productive → break streak, send notification
 * 4. On 1st of month → reset freeze/cheat allowances
 */
export const endOfDayWorker = new Worker(
  QUEUE_NAMES.END_OF_DAY,
  async (job) => {
    console.log('🌙 Running end-of-day resolution job...')

    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = yesterday.toISOString().split('T')[0]
    const yesterdayDow = yesterday.getDay()

    const today = new Date().toISOString().split('T')[0]
    const isFirstOfMonth = today.endsWith('-01')

    const users = await User.find({
      isActive: true,
      isDeleted: false,
    })
      .select('_id name currentStreakDays bestStreakDays notificationsEnabled')
      .lean()

    let productive = 0
    let broken = 0
    let noHabits = 0

    for (const user of users) {
      const userId = user._id.toString()

      try {
        // Find or create yesterday's day log
        const existingLog = await DayLog.findOne({ userId, date: yesterdayStr })

        // If already resolved (e.g. this job ran twice) — skip
        if (existingLog?.resolvedAt) continue

        // Check if user had any habits scheduled for yesterday
        const habitsYesterday = await Habit.find({
          userId,
          isActive: true,
          isArchived: false,
          activeDays: yesterdayDow,
          startDate: { $lte: yesterdayStr },
          $or: [{ endDate: null }, { endDate: { $gte: yesterdayStr } }],
        })
          .select('_id')
          .lean()

        if (habitsYesterday.length === 0) {
          // No habits yesterday — mark resolved, no streak impact
          await DayLog.findOneAndUpdate(
            { userId, date: yesterdayStr },
            { resolvedAt: new Date(), totalHabits: 0 },
            { upsert: true, new: true }
          )
          noHabits++
          continue
        }

        const habitIds = habitsYesterday.map((h) => h._id)
        const completedLogs = await HabitLog.countDocuments({
          userId,
          habitId: { $in: habitIds },
          date: yesterdayStr,
          isCompleted: true,
        })

        const isProductiveDay = completedLogs === habitsYesterday.length
        const productivityScore =
          habitsYesterday.length > 0
            ? Math.round((completedLogs / habitsYesterday.length) * 100)
            : 0

        // Check freeze/cheat protection
        const dayLog = await DayLog.findOneAndUpdate(
          { userId, date: yesterdayStr },
          {
            resolvedAt: new Date(),
            totalHabits: habitsYesterday.length,
            completedHabits: completedLogs,
            skippedHabits: habitsYesterday.length - completedLogs,
            isProductiveDay: isProductiveDay || existingLog?.isFreezeDay || existingLog?.isCheatDay,
            productivityScore,
          },
          { upsert: true, new: true }
        )

        const isProtected = dayLog.isFreezeDay || dayLog.isCheatDay
        const countAsGood = isProductiveDay || isProtected

        if (countAsGood) {
          // Award XP + check achievements
          await gamificationService.awardProductiveDay(userId)
          await achievementService.checkAndUnlock(userId, 'streak')
          productive++
        } else {
          // Streak broken
          if (user.currentStreakDays > 0) {
            // Archive current streak in streak history
            await streakService.recalculate(userId)

            if (user.notificationsEnabled) {
              await notificationService.sendFromTemplate(userId, 'streak_broken', {
                userName: user.name,
                streakCount: String(user.currentStreakDays),
              })
            }

            await User.findByIdAndUpdate(userId, { currentStreakDays: 0 })
            await deleteCache(CACHE_KEYS.userStreak(userId))
            await deleteCache(CACHE_KEYS.userProfile(userId))
          }
          broken++
        }
      } catch (err) {
        console.error(`❌ endOfDay failed for user ${userId}: ${err.message}`)
      }
    }

    // Reset monthly freeze/cheat allowances on 1st of month
    if (isFirstOfMonth) {
      await freezeService.resetMonthlyAllowances()
      console.log('❄️  Monthly freeze allowances reset')
    }

    console.log(
      `✅ End-of-day done — productive: ${productive}, broken: ${broken}, no habits: ${noHabits}`
    )
  },
  {
    connection: redis,
    concurrency: 1, // single concurrency — this is a heavy job
  }
)

endOfDayWorker.on('failed', (job, err) => {
  console.error(`❌ [endOfDayJob] failed: ${err.message}`)
})