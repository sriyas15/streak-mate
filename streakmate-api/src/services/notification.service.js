import { Notification, NotificationTemplate, FCMToken, User, Habit } from '../models/index.js'
import { sendPushNotification, sendMulticastNotification } from '../config/fcm.js'
import { emitToUser, SOCKET_EVENTS } from '../config/socket.js'

export const notificationService = {
  // ── Register FCM token ───────────────────────────────────────────
  registerToken: async (userId, { token, device, deviceId, deviceModel, appVersion }) => {
    await FCMToken.findOneAndUpdate(
      { token },
      { userId, token, device, deviceId, deviceModel, appVersion, isActive: true, lastUsedAt: new Date() },
      { upsert: true, new: true }
    )
  },

  // ── Remove FCM token (on logout) ─────────────────────────────────
  removeToken: async (userId, token) => {
    await FCMToken.findOneAndUpdate({ userId, token }, { isActive: false })
  },

  // ── Get notifications (paginated) ────────────────────────────────
  getNotifications: async (userId, { page, limit }) => {
    const skip = (Number(page) - 1) * Number(limit)
    const [notifications, total] = await Promise.all([
      Notification.find({ userId }).sort({ createdAt: -1 }).skip(skip).limit(Number(limit)).lean(),
      Notification.countDocuments({ userId }),
    ])
    return { notifications, total, page: Number(page), limit: Number(limit) }
  },

  // ── Unread count ─────────────────────────────────────────────────
  getUnreadCount: async (userId) => {
    return Notification.countDocuments({ userId, isRead: false })
  },

  // ── Mark single read ─────────────────────────────────────────────
  markRead: async (userId, notificationId) => {
    await Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true, isSeen: true }
    )
  },

  // ── Mark all read ────────────────────────────────────────────────
  markAllRead: async (userId) => {
    await Notification.updateMany({ userId, isRead: false }, { isRead: true, isSeen: true })
  },

  // ── Delete single ────────────────────────────────────────────────
  deleteNotification: async (userId, notificationId) => {
    await Notification.findOneAndDelete({ _id: notificationId, userId })
  },

  // ── Clear all ────────────────────────────────────────────────────
  clearAll: async (userId) => {
    await Notification.deleteMany({ userId })
  },

  // ── Get preferences ──────────────────────────────────────────────
  getPreferences: async (userId) => {
    const user = await User.findById(userId)
      .select('notificationsEnabled reminderSoundEnabled')
      .lean()
    return user
  },

  // ── Update preferences ───────────────────────────────────────────
  updatePreferences: async (userId, updates) => {
    return User.findByIdAndUpdate(
      userId,
      { notificationsEnabled: updates.notificationsEnabled, reminderSoundEnabled: updates.reminderSoundEnabled },
      { new: true }
    ).select('notificationsEnabled reminderSoundEnabled')
  },

  // ── Get reminders ────────────────────────────────────────────────
  getReminders: async (userId) => {
    return Habit.find({ userId, reminderEnabled: true })
      .select('_id name icon reminderTimes reminderDays')
      .lean()
  },

  // ── Create reminder ──────────────────────────────────────────────
  createReminder: async (userId, { habitId, times, days }) => {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { reminderEnabled: true, reminderTimes: times, reminderDays: days || [0, 1, 2, 3, 4, 5, 6] },
      { new: true }
    )
    if (!habit) throwNotFound('Habit')
    return habit
  },

  // ── Update reminder ──────────────────────────────────────────────
  updateReminder: async (userId, habitId, updates) => {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      {
        reminderEnabled: updates.enabled ?? true,
        reminderTimes: updates.times,
        reminderDays: updates.days,
      },
      { new: true }
    )
    if (!habit) throwNotFound('Habit')
    return habit
  },

  // ── Delete reminder ──────────────────────────────────────────────
  deleteReminder: async (userId, habitId) => {
    await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { reminderEnabled: false, reminderTimes: [] }
    )
  },

  // ── Send test notification ───────────────────────────────────────
  sendTestNotification: async (userId) => {
    await notificationService.sendToUser(userId, {
      type: 'funny_morning',
      title: 'StreakMate Test 🔥',
      body: "This is a test notification. Your habits are watching 👀",
    })
  },

  // ── Core send to user ────────────────────────────────────────────
  // Main method used internally by all jobs + other services
  sendToUser: async (userId, { type, title, body, data = {}, habitId = null, deepLinkScreen = null, deepLinkParams = null }) => {
    const user = await User.findById(userId).select('notificationsEnabled').lean()
    if (!user?.notificationsEnabled) return

    const tokens = await FCMToken.find({ userId, isActive: true }).select('token device').lean()
    if (tokens.length === 0) return

    // Save to DB inbox
    const notification = await Notification.create({
      userId,
      habitId,
      type,
      title,
      body,
      deepLinkScreen,
      deepLinkParams,
      scheduledAt: new Date(),
    })

    // Send via FCM
    const tokenStrings = tokens.map((t) => t.token)
    const result = await sendMulticastNotification({
      tokens: tokenStrings,
      title,
      body,
      data: { notificationId: notification._id.toString(), type, ...data },
    })

    // Deactivate invalid tokens
    if (result.invalidTokens?.length > 0) {
      await FCMToken.updateMany(
        { token: { $in: result.invalidTokens } },
        { isActive: false }
      )
    }

    // Update delivery status
    await Notification.findByIdAndUpdate(notification._id, {
      sentAt: new Date(),
      isDelivered: result.success,
    })

    // Also emit via socket if user is online (instant in-app)
    emitToUser(userId, SOCKET_EVENTS.NEW_NOTIFICATION, notification)

    return notification
  },

  // ── Send from template (with random body variant) ────────────────
  sendFromTemplate: async (userId, type, variables = {}) => {
    const template = await NotificationTemplate.findOne({ type, isActive: true }).lean()
    if (!template) return

    // Pick a random body variant
    const bodyVariant = template.bodyVariants[
      Math.floor(Math.random() * template.bodyVariants.length)
    ]

    // Replace variables: {{ userName }} → "Riyan"
    let title = template.title
    let body = bodyVariant
    for (const [key, value] of Object.entries(variables)) {
      title = title.replace(new RegExp(`{{\\s*${key}\\s*}}`, 'g'), value)
      body = body.replace(new RegExp(`{{\\s*${key}\\s*}}`, 'g'), value)
    }

    return notificationService.sendToUser(userId, { type, title, body })
  },
}

const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}