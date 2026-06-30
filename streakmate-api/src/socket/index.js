import { Server } from 'socket.io'
import jwt from 'jsonwebtoken'
import { env } from '../config/env.js'
import { User } from '../models/index.js'
import { SOCKET_EVENTS } from './events.js'
import { registerFriendHandlers } from './handlers/friend.handler.js'
import { registerStreakHandlers } from './handlers/streak.handler.js'
import { registerNotificationHandlers } from './handlers/notification.handler.js'

let io = null

// userId → Set of socketIds
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
    transports: ['websocket', 'polling'],
  })

  // ─── JWT Auth Middleware ─────────────────────────────────────────
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '')

      if (!token) return next(new Error('SOCKET_NO_TOKEN'))

      const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET)

      const user = await User.findById(decoded.userId)
        .select('_id name username profilePicture isActive isDeleted')
        .lean()

      if (!user || !user.isActive || user.isDeleted) {
        return next(new Error('SOCKET_USER_INVALID'))
      }

      socket.userId = decoded.userId.toString()
      socket.user = user
      next()
    } catch (err) {
      if (err.name === 'TokenExpiredError') return next(new Error('SOCKET_TOKEN_EXPIRED'))
      if (err.name === 'JsonWebTokenError') return next(new Error('SOCKET_TOKEN_INVALID'))
      next(new Error('SOCKET_AUTH_FAILED'))
    }
  })

  // ─── Connection ──────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const userId = socket.userId
  // Track online users
    if (!onlineUsers.has(userId)) onlineUsers.set(userId, new Set())
    onlineUsers.get(userId).add(socket.id)

    // Join personal room
    socket.join(`user:${userId}`)

    console.log(`🔌 Socket connected: ${userId} (${socket.id}) — online: ${onlineUsers.size}`)

    // ─── Register domain handlers ──────────────────────────────────
    registerFriendHandlers(io, socket)
    registerStreakHandlers(io, socket)
    registerNotificationHandlers(io, socket)

    // ─── Ping / Pong ───────────────────────────────────────────────
    socket.on(SOCKET_EVENTS.PING, () => {
      socket.emit(SOCKET_EVENTS.PONG, { ts: Date.now() })
    })

    // ─── Disconnect ────────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      const sockets = onlineUsers.get(userId)
      if (sockets) {
        sockets.delete(socket.id)
        if (sockets.size === 0) onlineUsers.delete(userId)
      }
      console.log(`🔌 Socket disconnected: ${userId} — ${reason} — online: ${onlineUsers.size}`)
    })

    // ─── Error ─────────────────────────────────────────────────────
    socket.on('error', (err) => {
      console.error(`❌ Socket error for ${userId}: ${err.message}`)
    })
  })

  console.log('✅ Socket.io initialized')
  return io
}

// ─── Exported helpers ────────────────────────────────────────────────────────

export const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized')
  return io
}

export const emitToUser = (userId, event, data) => {
  if (!io) return
  io.to(`user:${userId.toString()}`).emit(event, data)
}

export const isUserOnline = (userId) => onlineUsers.has(userId.toString())

export const getOnlineUserIds = () => [...onlineUsers.keys()]

export { SOCKET_EVENTS }