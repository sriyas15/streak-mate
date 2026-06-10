import jwt from 'jsonwebtoken'
import { env } from '../config/env.js'

// ─── Sign tokens ─────────────────────────────────────────────────────────────
export const signAccessToken = (userId) =>
  jwt.sign({ userId: userId.toString() }, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
    issuer: 'streakmate',
    audience: 'streakmate-app',
  })

export const signRefreshToken = (userId) =>
  jwt.sign({ userId: userId.toString() }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
    issuer: 'streakmate',
    audience: 'streakmate-app',
  })

// ─── Verify tokens ───────────────────────────────────────────────────────────
export const verifyAccessToken = (token) =>
  jwt.verify(token, env.JWT_ACCESS_SECRET, {
    issuer: 'streakmate',
    audience: 'streakmate-app',
  })

export const verifyRefreshToken = (token) =>
  jwt.verify(token, env.JWT_REFRESH_SECRET, {
    issuer: 'streakmate',
    audience: 'streakmate-app',
  })

// ─── Decode without verification (for expired token inspection) ──────────────
export const decodeToken = (token) => jwt.decode(token)

// ─── Extract userId from token without throwing ──────────────────────────────
export const extractUserId = (token) => {
  try {
    const decoded = jwt.decode(token)
    return decoded?.userId || null
  } catch {
    return null
  }
}

// ─── Check if token is expired ───────────────────────────────────────────────
export const isTokenExpired = (token) => {
  try {
    const decoded = jwt.decode(token)
    if (!decoded?.exp) return true
    return Date.now() >= decoded.exp * 1000
  } catch {
    return true
  }
}