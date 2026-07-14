import { Queue } from 'bullmq'
import { redis } from '../config/redis.js'
import { QUEUE_NAMES } from '../config/bullmq.js'
import { Streak } from '../models/index.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'

// One Queue instance per queue name — used only to schedule jobs.
// The actual processing logic lives in scheduler.service.js workers,
// which are untouched by this file.
const queues = {}
const getQueue = (name) => {
  if (!queues[name]) {
    queues[name] = new Queue(name, { connection: redis })
  }
  return queues[name]
}

/**
 * Registers all repeatable (cron) jobs. Call this ONCE on server boot,
 * after Redis is connected. Safe to call on every restart — BullMQ
 * deduplicates repeatable jobs by jobId.
 */
export const registerScheduledJobs = async () => {
  await getQueue(QUEUE_NAMES.END_OF_DAY).add(
    'daily-resolution',
    {},
    { repeat: { pattern: '0 0 * * *' }, jobId: 'end-of-day-daily' }
  )

  await getQueue(QUEUE_NAMES.STREAK_WARNING).add(
    'streak-warning',
    {},
    { repeat: { pattern: '0 21 * * *' }, jobId: 'streak-warning-daily' }
  )

  await getQueue(QUEUE_NAMES.FUNNY_NOTIF).add(
    'funny-notif',
    {},
    { repeat: { pattern: '0 11 * * *' }, jobId: 'funny-notif-daily' }
  )

  await getQueue(QUEUE_NAMES.WEEKLY_REPORT).add(
    'weekly-report',
    {},
    { repeat: { pattern: '0 20 * * 0' }, jobId: 'weekly-report' }
  )

  await getQueue(QUEUE_NAMES.MONTHLY_REPORT).add(
    'monthly-report',
    {},
    { repeat: { pattern: '0 9 1 * *' }, jobId: 'monthly-report' }
  )

  console.log('🕒 Scheduled jobs registered')
}
// in jobScheduler.service.js — add this export
export const endOfDayQueue = getQueue(QUEUE_NAMES.END_OF_DAY)