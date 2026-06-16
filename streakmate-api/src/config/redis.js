import { Redis } from 'ioredis'
import { env } from './env.js'

// ─── Connection options ─────────────────────────────────────────────────────
const redisOptions = {
  maxRetriesPerRequest: null, // required by BullMQ
  enableReadyCheck: false,    // required by BullMQ
  retryStrategy(times) {
    if (times > 10) {
      console.error('❌ Redis: max retries reached, giving up')
      return null
    }
    const delay = Math.min(times * 100, 3000)
    console.warn(`⚠️  Redis retry attempt ${times} — retrying in ${delay}ms`)
    return delay
  },
}

// ─── Build connection config ─────────────────────────────────────────────────
// In production use REDIS_URL (Railway/Render), in dev use host+port
const getRedisConfig = () => {
  if (env.REDIS_URL) {
    return { ...redisOptions, lazyConnect: true }
  }
  return {
    ...redisOptions,
    host: env.REDIS_HOST,
    port: env.REDIS_PORT,
    username: env.REDIS_USERNAME,
    password: env.REDIS_PASSWORD || undefined,
    lazyConnect: true,
  }
}

// ─── Default client — for caching, sessions, general use ────────────────────
const createRedisClient = () => {
  const client = env.REDIS_URL
    ? new Redis(env.REDIS_URL, redisOptions)
    : new Redis(getRedisConfig())

  client.on('connect', () => console.log('✅ Redis connected'))
  client.on('ready', () => console.log('✅ Redis ready'))
  client.on('error', (err) => console.error(`❌ Redis error: ${err.message}`))
  client.on('close', () => console.warn('⚠️  Redis connection closed'))
  client.on('reconnecting', () => console.warn('⚠️  Redis reconnecting...'))

  return client
}

// ─── Separate subscriber client — for pub/sub ───────────────────────────────
// Redis requires a dedicated connection for subscribe mode
const createSubscriberClient = () => {
  const client = env.REDIS_URL
    ? new Redis(env.REDIS_URL, redisOptions)
    : new Redis(getRedisConfig())

  client.on('connect', () => console.log('✅ Redis subscriber connected'))
  client.on('error', (err) => console.error(`❌ Redis subscriber error: ${err.message}`))

  return client
}

// ─── Singleton instances ────────────────────────────────────────────────────
export const redis = createRedisClient()
export const redisSubscriber = createSubscriberClient()

// ─── Connect both ───────────────────────────────────────────────────────────
export const connectRedis = async () => {
  try {
    await redis.connect()
    await redisSubscriber.connect()
  } catch (err) {
    console.error(`❌ Redis connection failed: ${err.message}`)
    // process.exit(1)
  }
}

// ─── Graceful shutdown ──────────────────────────────────────────────────────
export const disconnectRedis = async () => {
  await redis.quit()
  await redisSubscriber.quit()
  console.log('🔌 Redis connections closed')
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Set a value with optional TTL (seconds)
 */

// export const setCache = async (key, value, ttlSeconds = null) => {
//   const serialized = JSON.stringify(value)
//   if (ttlSeconds) {
//     await redis.set(key, serialized, 'EX', ttlSeconds)
//   } else {
//     await redis.set(key, serialized)
//   }
// }

// /**
//  * Get a parsed value by key. Returns null if not found.
//  */
// export const getCache = async (key) => {
//   const data = await redis.get(key)
//   return data ? JSON.parse(data) : null
// }

// /**
//  * Delete a key
//  */
// export const deleteCache = async (key) => {
//   await redis.del(key)
// }

// /**
//  * Delete all keys matching a pattern
//  * e.g. deletePattern("streak:userId:*")
//  */
// export const deletePattern = async (pattern) => {
//   const keys = await redis.keys(pattern)
//   if (keys.length > 0) {
//     await redis.del(...keys)
//   }
// }

export const setCache = async (key, value, ttlSeconds = null) => {
  try {
    const serialized = JSON.stringify(value)
    if (ttlSeconds) {
      await redis.set(key, serialized, 'EX', ttlSeconds)
    } else {
      await redis.set(key, serialized)
    }
  } catch { /* ignore */ }
}

export const getCache = async (key) => {
  try {
    const data = await redis.get(key)
    return data ? JSON.parse(data) : null
  } catch { return null }
}

export const deleteCache = async (key) => {
  try { await redis.del(key) } catch { /* ignore */ }
}

export const deletePattern = async (pattern) => {
  try {
    const keys = await redis.keys(pattern)
    if (keys.length > 0) await redis.del(...keys)
  } catch { /* ignore */ }
}

// ─── Cache key constants ────────────────────────────────────────────────────
export const CACHE_KEYS = {
  userProfile: (userId) => `user:${userId}:profile`,
  userStreak: (userId) => `user:${userId}:streak`,
  habitStreak: (userId, habitId) => `user:${userId}:habit:${habitId}:streak`,
  todayHabits: (userId) => `user:${userId}:today:habits`,
  leaderboard: (type) => `leaderboard:${type}`,           // "friends" | "global"
  analytics: (userId, period) => `user:${userId}:analytics:${period}`,
  calendarMonth: (userId, month) => `user:${userId}:calendar:${month}`,
}

// ─── TTL constants (seconds) ─────────────────────────────────────────────────
export const TTL = {
  SHORT: 60,           // 1 min  — today's habits, live data
  MEDIUM: 60 * 15,     // 15 min — streak counts, leaderboard
  LONG: 60 * 60,       // 1 hr   — analytics, calendar
  DAY: 60 * 60 * 24,   // 24 hrs — profile, static data
}