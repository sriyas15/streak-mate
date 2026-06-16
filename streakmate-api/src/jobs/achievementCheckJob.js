import { Worker } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { achievementService } from '../services/achievement.service.js'

/**
 * Achievement Check Job
 *
 * Triggered by other services after key events:
 * - habit completed    → trigger: "habit_complete" | "streak_7" | "streak_30" etc
 * - friend added       → trigger: "add_5_friends"
 * - nudge sent         → trigger: "nudge_sent"
 * - perfect week       → trigger: "perfect_week"
 *
 * Job data: { userId, trigger }
 *
 * Deduplication key prevents the same trigger from being checked
 * multiple times in quick succession.
 */
export const achievementCheckWorker = new Worker(
  QUEUE_NAMES.ACHIEVEMENT_CHECK,
  async (job) => {
    const { userId, trigger } = job.data

    if (!userId || !trigger) {
      console.warn(`⚠️  achievementCheckJob: missing userId or trigger`)
      return
    }

    console.log(`🏆 Checking achievements for ${userId} — trigger: ${trigger}`)

    await achievementService.checkAndUnlock(userId, trigger)

    console.log(`✅ Achievement check done for ${userId} — trigger: ${trigger}`)
  },
  {
    connection: redis,
    concurrency: 10, // fast — just DB reads + optional writes
  }
)

achievementCheckWorker.on('failed', (job, err) => {
  console.error(`❌ [achievementCheckJob] ${job?.id} failed: ${err.message}`)
})