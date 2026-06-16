import { SOCKET_EVENTS } from '../events.js'
import { User } from '../../models/index.js'
import { notificationService } from '../../services/notification.service.js'
import { isUserOnline } from '../../config/socket.js'

/**
 * Friend handler
 * Registered per socket connection in socket/index.js
 */
export const registerFriendHandlers = (io, socket) => {
  const userId = socket.userId.toString()

  // ── Send nudge to a friend ─────────────────────────────────────
  socket.on(SOCKET_EVENTS.SEND_NUDGE, async ({ targetUserId }) => {
    try {
      if (!targetUserId) return

      // Verify they are actually friends
      const user = await User.findById(userId).select('name friendIds').lean()
      const isFriend = user.friendIds.map(String).includes(String(targetUserId))
      if (!isFriend) {
        return socket.emit(SOCKET_EVENTS.ERROR, { message: 'Not friends with this user' })
      }

      const nudgePayload = {
        from: {
          userId,
          name: user.name,
          username: socket.user.username,
          profilePicture: socket.user.profilePicture,
        },
        sentAt: new Date().toISOString(),
      }

      // Real-time if friend is online
      if (isUserOnline(targetUserId)) {
        io.to(`user:${targetUserId}`).emit(SOCKET_EVENTS.RECEIVE_NUDGE, nudgePayload)
      }

      // Push notification if offline (or supplement real-time)
      await notificationService.sendToUser(targetUserId, {
        type: 'friend_nudge',
        title: 'Nudge! 👊',
        body: `${user.name} is checking on your habits. Don't let them down!`,
        deepLinkScreen: 'Home',
      })
    } catch (err) {
      console.error(`❌ SEND_NUDGE error: ${err.message}`)
      socket.emit(SOCKET_EVENTS.ERROR, { message: 'Failed to send nudge' })
    }
  })

  // ── Online status check ────────────────────────────────────────
  socket.on('friend:online_status', async ({ friendIds }) => {
    try {
      if (!Array.isArray(friendIds)) return

      const statuses = {}
      for (const fId of friendIds) {
        statuses[fId] = isUserOnline(fId)
      }

      socket.emit('friend:online_status:response', statuses)
    } catch (err) {
      console.error(`❌ online_status error: ${err.message}`)
    }
  })
}