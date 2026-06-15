import jwt from 'jsonwebtoken'
import crypto from 'crypto'
import { User } from '../models/index.js'
import { env } from '../config/env.js'
import { setCache, deleteCache, CACHE_KEYS } from '../config/redis.js'
import { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken } from '../utils/jwt.js'

// ─── Auth service ────────────────────────────────────────────────────────────
export const authService = {
  // ── Register ────────────────────────────────────────────────────
  register: async ({ name, username, email, password }) => {
    const existingEmail = await User.findOne({ email }).select('_id')
    if (existingEmail) {
      const err = new Error('Email already in use')
      err.statusCode = 409
      throw err
    }

    const existingUsername = await User.findOne({ username }).select('_id')
    if (existingUsername) {
      const err = new Error('Username already taken')
      err.statusCode = 409
      throw err
    }

    const verificationToken = crypto.randomBytes(32).toString('hex')
    const verificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000) // 24hrs

    const user = await User.create({
      name,
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      password,
      emailVerificationToken: verificationToken,
      emailVerificationExpiry: verificationExpiry,
    })

    const accessToken = signAccessToken(user._id)
    const refreshToken = signRefreshToken(user._id)

    // Save refresh token to user
    await User.findByIdAndUpdate(user._id, { refreshToken })

    // TODO: send verification email via scheduler

    return {
      accessToken,
      refreshToken,
      user: sanitizeUser(user),
    }
  },

  // ── Login ───────────────────────────────────────────────────────
  login: async ({ email, password }) => {
    const user = await User.findOne({ email: email.toLowerCase() }).select('+password +refreshToken')
    if (!user) {
      const err = new Error('Invalid email or password')
      err.statusCode = 401
      throw err
    }

    const isMatch = await user.comparePassword(password)
    if (!isMatch) {
      const err = new Error('Invalid email or password')
      err.statusCode = 401
      throw err
    }

    const accessToken = signAccessToken(user._id)
    const refreshToken = signRefreshToken(user._id)

    await User.findByIdAndUpdate(user._id, {
      refreshToken,
      lastActiveAt: new Date(),
    })

    // Invalidate any cached profile
    // await deleteCache(CACHE_KEYS.userProfile(user._id))

    return {
      accessToken,
      refreshToken,
      user: sanitizeUser(user),
    }
  },

  // ── Logout ──────────────────────────────────────────────────────
  logout: async (userId) => {
    await User.findByIdAndUpdate(userId, { refreshToken: null })
    await deleteCache(CACHE_KEYS.userProfile(userId))
  },

  // ── Refresh token ───────────────────────────────────────────────
  refreshToken: async (token) => {
    let decoded
    try {
      decoded = verifyRefreshToken(token)
    } catch {
      const err = new Error('Invalid or expired refresh token')
      err.statusCode = 401
      throw err
    }

    const user = await User.findById(decoded.userId).select('+refreshToken')
    if (!user || user.refreshToken !== token) {
      const err = new Error('Refresh token revoked')
      err.statusCode = 401
      throw err
    }

    const newAccessToken = signAccessToken(user._id)
    const newRefreshToken = signRefreshToken(user._id)

    await User.findByIdAndUpdate(user._id, { refreshToken: newRefreshToken })

    return { accessToken: newAccessToken, refreshToken: newRefreshToken }
  },

  // ── Forgot password ─────────────────────────────────────────────
  forgotPassword: async (email) => {
    const user = await User.findOne({ email: email.toLowerCase() })
    if (!user) return // silent — prevents enumeration

    const resetToken = crypto.randomBytes(32).toString('hex')
    const resetExpiry = new Date(Date.now() + 60 * 60 * 1000) // 1hr

    await User.findByIdAndUpdate(user._id, {
      passwordResetToken: resetToken,
      passwordResetExpiry: resetExpiry,
    })

    // Store in Redis for fast lookup
    await setCache(`pwd_reset:${resetToken}`, user._id.toString(), 3600)

    // TODO: trigger email job via BullMQ
  },

  // ── Reset password ──────────────────────────────────────────────
  resetPassword: async ({ token, newPassword }) => {
    const user = await User.findOne({
      passwordResetToken: token,
      passwordResetExpiry: { $gt: new Date() },
    }).select('+passwordResetToken +passwordResetExpiry')

    if (!user) {
      const err = new Error('Reset token is invalid or has expired')
      err.statusCode = 400
      throw err
    }

    user.password = newPassword
    user.passwordResetToken = null
    user.passwordResetExpiry = null
    user.refreshToken = null // force re-login on all devices
    await user.save()

    await deleteCache(`pwd_reset:${token}`)
  },

  // ── Verify email ────────────────────────────────────────────────
  verifyEmail: async (token) => {
    const user = await User.findOne({
      emailVerificationToken: token,
      emailVerificationExpiry: { $gt: new Date() },
    }).select('+emailVerificationToken +emailVerificationExpiry')

    if (!user) {
      const err = new Error('Verification token is invalid or has expired')
      err.statusCode = 400
      throw err
    }

    await User.findByIdAndUpdate(user._id, {
      isEmailVerified: true,
      emailVerificationToken: null,
      emailVerificationExpiry: null,
    })
  },

  // ── Resend verification ─────────────────────────────────────────
  resendVerification: async (userId) => {
    const user = await User.findById(userId)
    if (user.isEmailVerified) {
      const err = new Error('Email is already verified')
      err.statusCode = 400
      throw err
    }

    const verificationToken = crypto.randomBytes(32).toString('hex')
    const verificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000)

    await User.findByIdAndUpdate(userId, {
      emailVerificationToken: verificationToken,
      emailVerificationExpiry: verificationExpiry,
    })

    // TODO: trigger email job
  },

  // ── Google OAuth ────────────────────────────────────────────────
  googleAuth: async (idToken) => {
    // Verify Google ID token with firebase-admin or google-auth-library
    // For now: placeholder — integrate with your OAuth provider
    const err = new Error('Google auth not yet implemented')
    err.statusCode = 501
    throw err
  },

  // ── Apple OAuth ─────────────────────────────────────────────────
  appleAuth: async ({ idToken, fullName }) => {
    const err = new Error('Apple auth not yet implemented')
    err.statusCode = 501
    throw err
  },
}

// ─── Strip sensitive fields before sending user to client ───────────────────
const sanitizeUser = (user) => {
  const obj = user.toObject ? user.toObject() : { ...user }
  delete obj.password
  delete obj.refreshToken
  delete obj.emailVerificationToken
  delete obj.emailVerificationExpiry
  delete obj.passwordResetToken
  delete obj.passwordResetExpiry
  return obj
}