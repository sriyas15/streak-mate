import { redis } from '../config/redis.js'
import { env } from '../config/env.js'

/**
 * Rate limiter using Redis sliding window
 *
 * Different limits per route type:
 * - auth routes (login/register) → strict: 10 req / 15 min
 * - standard API routes          → normal: 100 req / 1 min
 * - notification send            → 20 req / 1 min (prevent spam)
 * - friend nudge                 → 5 req / 10 min (per target user)
 * - sync endpoint                → 30 req / 1 min
 */

const LIMITS = {
  auth: { max: 10, windowMs: 15 * 60 * 1000 },        // 10 per 15 min
  standard: { max: 100, windowMs: 60 * 1000 },          // 100 per 1 min
  notification: { max: 20, windowMs: 60 * 1000 },       // 20 per 1 min
  nudge: { max: 5, windowMs: 10 * 60 * 1000 },          // 5 per 10 min
  sync: { max: 30, windowMs: 60 * 1000 },               // 30 per 1 min
  habitLog: { max: 60, windowMs: 60 * 1000 },           // 60 per 1 min (frequent)
}

/**
 * Core rate limit factory
 * Returns a Fastify preHandler
 */
const createRateLimiter = (type = 'standard') => {
  const { max, windowMs } = LIMITS[type] || LIMITS.standard
  const windowSec = Math.ceil(windowMs / 1000)

  return async (req, reply) => {
    // Use userId if authenticated, fallback to IP
    const identifier = req.user?._id?.toString() || req.ip
    const key = `rate:${type}:${identifier}`

    try {
      const current = await redis.incr(key)

      if (current === 1) {
        await redis.expire(key, windowSec)
      }

      // Set headers for client visibility
      reply.header('X-RateLimit-Limit', max)
      reply.header('X-RateLimit-Remaining', Math.max(0, max - current))

      if (current > max) {
        const ttl = await redis.ttl(key)
        reply.header('X-RateLimit-Reset', ttl)

        return reply.code(429).send({
          success: false,
          message: 'Too many requests — please slow down',
          code: 'RATE_LIMIT_EXCEEDED',
          retryAfter: ttl,
        })
      }
    } catch (err) {
      // If Redis fails — don't block the request, just log
      req.log.warn(`Rate limiter Redis error: ${err.message}`)
    }
  }
}

// ─── Exported limiters ────────────────────────────────────────────────────────
export const authRateLimiter = createRateLimiter('auth')
export const standardRateLimiter = createRateLimiter('standard')
export const notificationRateLimiter = createRateLimiter('notification')
export const nudgeRateLimiter = createRateLimiter('nudge')
export const syncRateLimiter = createRateLimiter('sync')
export const habitLogRateLimiter = createRateLimiter('habitLog')