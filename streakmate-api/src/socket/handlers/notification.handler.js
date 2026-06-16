import { SOCKET_EVENTS } from '../events.js'
import { Notification } from '../../models/index.js'

/**
 * Notification handler
 * Handles real-time notification delivery and read receipts over socket
 */
export const registerNotificationHandlers = (io, socket) => {
  const userId = socket.userId.toString()

  // ── Client marks notification as seen via socket ───────────────
  socket.on('notification:seen', async ({ notificationId }) => {
    try {
      await Notification.findOneAndUpdate(
        { _id: notificationId, userId },
        { isSeen: true }
      )
    } catch (err) {
      console.error(`❌ notification:seen error: ${err.message}`)
    }
  })

  // ── Client requests unread count on reconnect ──────────────────
  socket.on('notification:unread_count', async () => {
    try {
      const count = await Notification.countDocuments({ userId, isRead: false })
      socket.emit('notification:unread_count:response', { count })
    } catch (err) {
      console.error(`❌ notification:unread_count error: ${err.message}`)
    }
  })

  // ── Mark all as read via socket ────────────────────────────────
  socket.on('notification:read_all', async () => {
    try {
      await Notification.updateMany(
        { userId, isRead: false },
        { isRead: true, isSeen: true }
      )
      socket.emit('notification:read_all:done', { success: true })
    } catch (err) {
      console.error(`❌ notification:read_all error: ${err.message}`)
    }
  })
}