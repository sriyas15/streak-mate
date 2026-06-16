import { notificationService } from '../services/notification.service.js'

export const notificationController = {
  // POST /notifications/token
  registerToken: async (req, reply) => {
    const { token, device, deviceId, deviceModel, appVersion } = req.body
    await notificationService.registerToken(req.user._id, {
      token, device, deviceId, deviceModel, appVersion,
    })
    return reply.send({ success: true, message: 'FCM token registered' })
  },

  // DELETE /notifications/token
  removeToken: async (req, reply) => {
    const { token } = req.body
    await notificationService.removeToken(req.user._id, token)
    return reply.send({ success: true, message: 'FCM token removed' })
  },

  // GET /notifications?page=1&limit=20
  getNotifications: async (req, reply) => {
    const { page = 1, limit = 20 } = req.query
    const result = await notificationService.getNotifications(req.user._id, { page, limit })
    return reply.send({ success: true, data: result })
  },

  // GET /notifications/unread-count
  getUnreadCount: async (req, reply) => {
    const count = await notificationService.getUnreadCount(req.user._id)
    return reply.send({ success: true, data: { count } })
  },

  // PATCH /notifications/:notificationId/read
  markRead: async (req, reply) => {
    await notificationService.markRead(req.user._id, req.params.notificationId)
    return reply.send({ success: true, message: 'Marked as read' })
  },

  // PATCH /notifications/read-all
  markAllRead: async (req, reply) => {
    await notificationService.markAllRead(req.user._id)
    return reply.send({ success: true, message: 'All notifications marked as read' })
  },

  // DELETE /notifications/:notificationId
  deleteNotification: async (req, reply) => {
    await notificationService.deleteNotification(req.user._id, req.params.notificationId)
    return reply.send({ success: true, message: 'Notification deleted' })
  },

  // DELETE /notifications/clear-all
  clearAll: async (req, reply) => {
    await notificationService.clearAll(req.user._id)
    return reply.send({ success: true, message: 'All notifications cleared' })
  },

  // GET /notifications/preferences
  getPreferences: async (req, reply) => {
    const preferences = await notificationService.getPreferences(req.user._id)
    return reply.send({ success: true, data: { preferences } })
  },

  // PATCH /notifications/preferences
  updatePreferences: async (req, reply) => {
    const preferences = await notificationService.updatePreferences(req.user._id, req.body)
    return reply.send({ success: true, message: 'Preferences updated', data: { preferences } })
  },

  // GET /notifications/reminders
  getReminders: async (req, reply) => {
    const reminders = await notificationService.getReminders(req.user._id)
    return reply.send({ success: true, data: { reminders } })
  },

  // POST /notifications/reminders
  createReminder: async (req, reply) => {
    const reminder = await notificationService.createReminder(req.user._id, req.body)
    return reply.code(201).send({ success: true, message: 'Reminder created', data: { reminder } })
  },

  // PATCH /notifications/reminders/:reminderId
  updateReminder: async (req, reply) => {
    const reminder = await notificationService.updateReminder(
      req.user._id,
      req.params.reminderId,
      req.body
    )
    return reply.send({ success: true, message: 'Reminder updated', data: { reminder } })
  },

  // DELETE /notifications/reminders/:reminderId
  deleteReminder: async (req, reply) => {
    await notificationService.deleteReminder(req.user._id, req.params.reminderId)
    return reply.send({ success: true, message: 'Reminder deleted' })
  },

  // POST /notifications/reminders/test
  sendTestNotification: async (req, reply) => {
    await notificationService.sendTestNotification(req.user._id)
    return reply.send({ success: true, message: 'Test notification sent' })
  },
}