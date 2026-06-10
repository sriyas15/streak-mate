import { Queue, Worker, QueueEvents, FlowProducer } from 'bullmq'
import { redis } from './redis.js'

// ─── Queue name constants ────────────────────────────────────────────────────
export const QUEUE_NAMES = {
  HABIT_REMINDER: 'habit-reminder',
  STREAK_WARNING: 'streak-warning',
  END_OF_DAY: 'end-of-day',
  WEEKLY_REPORT: 'weekly-report',
  MONTHLY_REPORT: 'monthly-report',
  FUNNY_NOTIF: 'funny-notification',
  ACHIEVEMENT_CHECK: 'achievement-check',
  PUSH_NOTIFICATION: 'push-notification',  // final delivery queue
  STREAK_SYNC: 'streak-sync',              // offline sync reconciliation
}

// ─── Shared connection for all queues ───────────────────────────────────────
const connection = redis

// ─── Default job options ─────────────────────────────────────────────────────
const defaultJobOptions = {
  attempts: 3,
  backoff: {
    type: 'exponential',
    delay: 1000, // 1s → 2s → 4s
  },
  removeOnComplete: {
    count: 100,  // keep last 100 completed jobs per queue
    age: 60 * 60 * 24, // max 24 hours
  },
  removeOnFail: {
    count: 500,  // keep last 500 failed for debugging
  },
}

// ─── Queue factory ───────────────────────────────────────────────────────────
const createQueue = (name) =>
  new Queue(name, {
    connection,
    defaultJobOptions,
  })

// ─── Queues ──────────────────────────────────────────────────────────────────
export const queues = {
  habitReminder: createQueue(QUEUE_NAMES.HABIT_REMINDER),
  streakWarning: createQueue(QUEUE_NAMES.STREAK_WARNING),
  endOfDay: createQueue(QUEUE_NAMES.END_OF_DAY),
  weeklyReport: createQueue(QUEUE_NAMES.WEEKLY_REPORT),
  monthlyReport: createQueue(QUEUE_NAMES.MONTHLY_REPORT),
  funnyNotif: createQueue(QUEUE_NAMES.FUNNY_NOTIF),
  achievementCheck: createQueue(QUEUE_NAMES.ACHIEVEMENT_CHECK),
  pushNotification: createQueue(QUEUE_NAMES.PUSH_NOTIFICATION),
  streakSync: createQueue(QUEUE_NAMES.STREAK_SYNC),
}

// ─── Queue events (for monitoring) ───────────────────────────────────────────
export const queueEvents = {
  pushNotification: new QueueEvents(QUEUE_NAMES.PUSH_NOTIFICATION, { connection }),
}

// ─── Scheduled / recurring jobs ──────────────────────────────────────────────
export const initScheduledJobs = async () => {
  // Streak warning — every day at 9:00 PM
  await queues.streakWarning.add(
    'daily-streak-warning',
    {},
    {
      repeat: { cron: '0 21 * * *' },
      jobId: 'streak-warning-daily', // prevent duplicates on restart
    }
  )

  // End of day resolution — every day at midnight
  await queues.endOfDay.add(
    'daily-end-of-day',
    {},
    {
      repeat: { cron: '0 0 * * *' },
      jobId: 'end-of-day-daily',
    }
  )

  // Weekly report — every Sunday at 8:00 PM
  await queues.weeklyReport.add(
    'weekly-report',
    {},
    {
      repeat: { cron: '0 20 * * 0' },
      jobId: 'weekly-report-sunday',
    }
  )

  // Monthly report — 1st of every month at 9:00 AM
  await queues.monthlyReport.add(
    'monthly-report',
    {},
    {
      repeat: { cron: '0 9 1 * *' },
      jobId: 'monthly-report-first',
    }
  )

  // Funny engagement notification — every day at 11:00 AM
  await queues.funnyNotif.add(
    'daily-funny-notif',
    {},
    {
      repeat: { cron: '0 11 * * *' },
      jobId: 'funny-notif-daily',
    }
  )

  console.log('✅ BullMQ scheduled jobs initialized')
}

// ─── Helper — add push notification job ──────────────────────────────────────
export const enqueuePushNotification = async (payload) => {
  return queues.pushNotification.add('send-push', payload, {
    priority: payload.priority || 2, // 1=high (streak broken), 2=normal, 3=low
  })
}

// ─── Helper — add achievement check for a user ───────────────────────────────
export const enqueueAchievementCheck = async (userId, trigger) => {
  return queues.achievementCheck.add('check', { userId, trigger }, {
    deduplication: { id: `achievement-${userId}-${trigger}` }, // no double-checks
  })
}

// ─── Graceful shutdown ──────────────────────────────────────────────────────
export const closeQueues = async () => {
  await Promise.all(Object.values(queues).map((q) => q.close()))
  console.log('🔌 BullMQ queues closed')
}