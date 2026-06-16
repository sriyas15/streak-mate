import { User } from '../models/index.js'
import { getCache, setCache, deleteCache, CACHE_KEYS, TTL } from '../config/redis.js'

export const userService = {
  // ── Get own profile ─────────────────────────────────────────────
  getProfile: async (userId) => {
    const cached = await getCache(CACHE_KEYS.userProfile(userId))
    if (cached) return cached

    const user = await User.findById(userId).lean()
    if (!user) throwNotFound('User')

    await setCache(CACHE_KEYS.userProfile(userId), user, TTL.MEDIUM)
    return user
  },

  // ── Update profile ──────────────────────────────────────────────
  updateProfile: async (userId, updates) => {
    const allowed = ['name', 'bio', 'username']
    const filtered = {}
    for (const key of allowed) {
      if (updates[key] !== undefined) filtered[key] = updates[key]
    }

    if (filtered.username) {
      filtered.username = filtered.username.toLowerCase()
      const taken = await User.findOne({ username: filtered.username, _id: { $ne: userId } })
      if (taken) throwConflict('Username already taken')
    }

    const user = await User.findByIdAndUpdate(userId, filtered, { new: true, runValidators: true })
    await deleteCache(CACHE_KEYS.userProfile(userId))
    return user
  },

  // ── Delete account (soft delete) ────────────────────────────────
  deleteAccount: async (userId) => {
    await User.findByIdAndUpdate(userId, {
      isDeleted: true,
      deletedAt: new Date(),
      refreshToken: null,
    })
    await deleteCache(CACHE_KEYS.userProfile(userId))
  },

  // ── Upload profile picture ──────────────────────────────────────
  uploadProfilePicture: async (userId, fileData) => {
    // TODO: upload to Cloudinary, get URL
    // const url = await cloudinaryService.upload(fileData)
    const url = 'https://placeholder.com/avatar.jpg' // replace when Cloudinary is set up
    await User.findByIdAndUpdate(userId, { profilePicture: url })
    await deleteCache(CACHE_KEYS.userProfile(userId))
    return url
  },

  // ── Delete profile picture ──────────────────────────────────────
  deleteProfilePicture: async (userId) => {
    await User.findByIdAndUpdate(userId, { profilePicture: null })
    await deleteCache(CACHE_KEYS.userProfile(userId))
  },

  // ── Get settings ────────────────────────────────────────────────
  getSettings: async (userId) => {
    const user = await User.findById(userId)
      .select('notificationsEnabled reminderSoundEnabled theme language timezone')
      .lean()
    if (!user) throwNotFound('User')
    return user
  },

  // ── Update settings ─────────────────────────────────────────────
  updateSettings: async (userId, updates) => {
    const allowed = ['notificationsEnabled', 'reminderSoundEnabled', 'theme', 'language']
    const filtered = {}
    for (const key of allowed) {
      if (updates[key] !== undefined) filtered[key] = updates[key]
    }

    const user = await User.findByIdAndUpdate(userId, filtered, { new: true })
      .select('notificationsEnabled reminderSoundEnabled theme language')
    await deleteCache(CACHE_KEYS.userProfile(userId))
    return user
  },

  // ── Update timezone ─────────────────────────────────────────────
  updateTimezone: async (userId, timezone) => {
    await User.findByIdAndUpdate(userId, { timezone })
    await deleteCache(CACHE_KEYS.userProfile(userId))
  },

  // ── Public profile ───────────────────────────────────────────────
  getPublicProfile: async (targetUserId, requestingUserId) => {
    const user = await User.findById(targetUserId)
      .select('name username profilePicture bio level xpPoints currentStreakDays bestStreakDays createdAt')
      .lean()
    if (!user) throwNotFound('User')

    // Check if they are friends
    const requestingUser = await User.findById(requestingUserId).select('friendIds').lean()
    user.isFriend = requestingUser.friendIds.map(String).includes(String(targetUserId))

    return user
  },

  // ── User stats (for friends to see) ─────────────────────────────
  getUserStats: async (userId) => {
    const user = await User.findById(userId)
      .select('currentStreakDays bestStreakDays level xpPoints')
      .lean()
    if (!user) throwNotFound('User')
    return user
  },
}

// ─── Error helpers ───────────────────────────────────────────────────────────
const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}

const throwConflict = (message) => {
  const err = new Error(message)
  err.statusCode = 409
  throw err
}