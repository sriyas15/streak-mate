import { verifyAccessToken } from '../utils/jwt.js'
import { User } from '../models/index.js'
import { getCache, setCache, CACHE_KEYS, TTL } from '../config/redis.js'

/**
 * authenticate
 * Fastify preHandler — verifies JWT access token on every protected route
 *
 * Attaches req.user (full user doc) to the request
 * Uses Redis cache to avoid hitting MongoDB on every request
 */
export const authenticate = async (req, reply) => {
  try {
    const authHeader = req.headers.authorization
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return reply.code(401).send({
        success: false,
        message: 'No token provided',
        code: 'AUTH_NO_TOKEN',
      })
    }
    const token = authHeader.split(' ')[1]
    let decoded
    console.log('INCOMING TOKEN:', token)
    try {
      decoded = verifyAccessToken(token)
    } catch (err) {
      const code = err.name === 'TokenExpiredError' ? 'AUTH_TOKEN_EXPIRED' : 'AUTH_TOKEN_INVALID'
      const message = err.name === 'TokenExpiredError'
        ? 'Access token expired — please refresh'
        : 'Invalid token'
      return reply.code(401).send({ success: false, message, code })
    }

    const userId = decoded.userId

    // Try cache first
    const cached = await getCache(CACHE_KEYS.userProfile(userId))
    if (cached) {
      req.user = cached
      return // continue
    }

    // Fallback to DB
    const user = await User.findById(userId).select('-password -refreshToken -emailVerificationToken -passwordResetToken').lean()

    if (!user) {
      return reply.code(401).send({
        success: false,
        message: 'User not found',
        code: 'AUTH_USER_NOT_FOUND',
      })
    }

    if (!user.isActive || user.isDeleted) {
      return reply.code(403).send({
        success: false,
        message: 'Account is inactive or deleted',
        code: 'AUTH_ACCOUNT_INACTIVE',
      })
    }

    // Cache for next request
    await setCache(CACHE_KEYS.userProfile(userId), user, TTL.MEDIUM)

    req.user = user
  } catch (err) {
    req.log.error(err)
    return reply.code(500).send({
      success: false,
      message: 'Authentication error',
      code: 'AUTH_ERROR',
    })
  }
}

/**
 * optionalAuthenticate
 * Like authenticate but doesn't block — used for public routes
 * that behave differently when logged in (e.g. public profiles)
 */
export const optionalAuthenticate = async (req, reply) => {
  const authHeader = req.headers.authorization
  if (!authHeader || !authHeader.startsWith('Bearer ')) return

  try {
    const token = authHeader.split(' ')[1]
    const decoded = verifyAccessToken(token)
    const user = await User.findById(decoded.userId)
      .select('-password -refreshToken')
      .lean()
    if (user?.isActive && !user.isDeleted) req.user = user
  } catch {
    // Silently ignore — optional auth
  }
}

/**
 * requireEmailVerified
 * Use after authenticate for routes that need verified email
 */
export const requireEmailVerified = async (req, reply) => {
  if (!req.user?.isEmailVerified) {
    return reply.code(403).send({
      success: false,
      message: 'Please verify your email to access this feature',
      code: 'AUTH_EMAIL_NOT_VERIFIED',
    })
  }
}

/**
 * requireOnboarding
 * Blocks access to app routes until onboarding is complete
 * Exempts: /onboarding/* and /auth/* routes
 */
export const requireOnboarding = async (req, reply) => {
  if (!req.user?.onboardingCompleted) {
    return reply.code(403).send({
      success: false,
      message: 'Please complete onboarding first',
      code: 'ONBOARDING_INCOMPLETE',
      data: { onboardingStep: req.user?.onboardingStep || 1 },
    })
  }
}