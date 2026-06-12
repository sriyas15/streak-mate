import { notificationController } from '../controllers/notification.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const notificationRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  // ─── FCM Token ────────────────────────────────────────────────
  fastify.post('/token', { handler: notificationController.registerToken })
  fastify.delete('/token', { handler: notificationController.removeToken })

  // ─── Inbox ────────────────────────────────────────────────────
  fastify.get('/', { handler: notificationController.getNotifications })
  fastify.get('/unread-count', { handler: notificationController.getUnreadCount })
  fastify.patch('/:notificationId/read', { handler: notificationController.markRead })
  fastify.patch('/read-all', { handler: notificationController.markAllRead })
  fastify.delete('/:notificationId', { handler: notificationController.deleteNotification })
  fastify.delete('/clear-all', { handler: notificationController.clearAll })

  // ─── Preferences ──────────────────────────────────────────────
  fastify.get('/preferences', { handler: notificationController.getPreferences })
  fastify.patch('/preferences', { handler: notificationController.updatePreferences })

  // ─── Reminders ────────────────────────────────────────────────
  fastify.get('/reminders', { handler: notificationController.getReminders })
  fastify.post('/reminders', { handler: notificationController.createReminder })
  fastify.patch('/reminders/:reminderId', { handler: notificationController.updateReminder })
  fastify.delete('/reminders/:reminderId', { handler: notificationController.deleteReminder })
  fastify.post('/reminders/test', { handler: notificationController.sendTestNotification })
}