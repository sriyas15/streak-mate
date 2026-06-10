import { Server } from 'socket.io'
import jwt from 'jsonwebtoken'
import { env } from './env.js'
import { User } from '../models/index.js'

let io = null

// ─── Active user socket map — userId → Set of socketIds ─────────────────────
// Kept in memory; for multi-instance production use Redis adapter
const onlineUsers = new Map()

export const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: env.CLIENT_URL,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  })

  // ─── Auth middleware — verify JWT on every connection ─────────────────────
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '')

      if (!token) {
        return next(new Error('SOCKET_AUTH_MISSING'))
      }

      const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET)
      const user = await User.findById(decoded.userId).select('_id name username profilePicture')

      if (!user) {
        return next(new Error('SOCKET_AUTH_INVALID'))
      }

      socket.userId = decoded.userId
      socket.user = user
      next()
    } catch (err) {
      next(new Error('SOCKET_AUTH_FAILED'))
    }
  })

  // ─── Connection handler ───────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const userId = socket.userId.toString()
    console.log(`🔌 Socket connected: ${userId} (${socket.id})`)

    // Track online users
    if (!onlineUsers.has(userId)) {
      onlineUsers.set(userId, new Set())
    }
    onlineUsers.get(userId).add(socket.id)

    // Join personal room for targeted events
    socket.join(`user:${userId}`)

    // ─── Events ─────────────────────────────────────────────────
    socket.on(SOCKET_EVENTS.HABIT_COMPLETED, (data) => {
      // Broadcast to friends that user completed a habit
      socket.to(`user:${userId}`).emit(SOCKET_EVENTS.HABIT_COMPLETED, {
        userId,
        ...data,
      })
    })

    socket.on(SOCKET_EVENTS.SEND_NUDGE, ({ targetUserId }) => {
      // Forward nudge to target user's room
      io.to(`user:${targetUserId}`).emit(SOCKET_EVENTS.RECEIVE_NUDGE, {
        from: socket.user,
        sentAt: new Date(),
      })
    })

    socket.on(SOCKET_EVENTS.PING, () => {
      socket.emit(SOCKET_EVENTS.PONG, { ts: Date.now() })
    })

    // ─── Disconnect ─────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      const sockets = onlineUsers.get(userId)
      if (sockets) {
        sockets.delete(socket.id)
        if (sockets.size === 0) {
          onlineUsers.delete(userId)
        }
      }
      console.log(`🔌 Socket disconnected: ${userId} — ${reason}`)
    })
  })

  console.log('✅ Socket.io initialized')
  return io
}

// ─── Get io instance anywhere in the app ────────────────────────────────────
export const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized — call initSocket first')
  return io
}

// ─── Emit to a specific user ─────────────────────────────────────────────────
export const emitToUser = (userId, event, data) => {
  if (!io) return
  io.to(`user:${userId.toString()}`).emit(event, data)
}

// ─── Check if a user is online ───────────────────────────────────────────────
export const isUserOnline = (userId) => {
  return onlineUsers.has(userId.toString())
}

// ─── Get all online user IDs ─────────────────────────────────────────────────
export const getOnlineUserIds = () => {
  return [...onlineUsers.keys()]
}

// ─── Socket event name constants ─────────────────────────────────────────────
export const SOCKET_EVENTS = {
  // Habit
  HABIT_COMPLETED: 'habit:completed',
  STREAK_UPDATED: 'streak:updated',
  STREAK_BROKEN: 'streak:broken',
  STREAK_MILESTONE: 'streak:milestone',

  // Friends
  SEND_NUDGE: 'friend:nudge:send',
  RECEIVE_NUDGE: 'friend:nudge:receive',
  FRIEND_REQUEST_RECEIVED: 'friend:request:received',
  FRIEND_ACCEPTED: 'friend:accepted',
  LEADERBOARD_UPDATED: 'leaderboard:updated',
  FRIEND_STREAK_OVERTAKE: 'friend:streak:overtake',

  // Notifications
  NEW_NOTIFICATION: 'notification:new',

  // System
  PING: 'ping',
  PONG: 'pong',
}