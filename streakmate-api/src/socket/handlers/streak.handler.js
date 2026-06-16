import { SOCKET_EVENTS } from '../events.js'
import { User, Streak } from '../../models/index.js'
import { isUserOnline } from '../../config/socket.js'

/**
 * Streak handler
 * Handles real-time streak milestone broadcasts and friend leaderboard nudges
 */
export const registerStreakHandlers = (io, socket) => {
  const userId = socket.userId.toString()

  // ── Client requests latest streak data ────────────────────────
  socket.on('streak:request', async () => {
    try {
      const streak = await Streak.findOne({ userId, habitId: null }).lean()
      socket.emit(SOCKET_EVENTS.STREAK_UPDATED, {
        currentStreak: streak?.currentStreakCount || 0,
        bestStreak: streak?.bestStreakCount || 0,
        lastUpdated: streak?.lastUpdated,
      })
    } catch (err) {
      console.error(`❌ streak:request error: ${err.message}`)
    }
  })

  // ── Broadcast streak milestone to online friends ───────────────
  // Called internally after streakService detects a milestone
  socket.on(SOCKET_EVENTS.STREAK_MILESTONE, async ({ days }) => {
    try {
      const user = await User.findById(userId).select('name username profilePicture friendIds currentStreakDays').lean()

      // Notify online friends of the milestone
      for (const friendId of user.friendIds) {
        const fIdStr = friendId.toString()
        if (!isUserOnline(fIdStr)) continue

        io.to(`user:${fIdStr}`).emit(SOCKET_EVENTS.FRIEND_STREAK_OVERTAKE, {
          user: {
            userId,
            name: user.name,
            username: user.username,
            profilePicture: user.profilePicture,
          },
          streakDays: days || user.currentStreakDays,
          milestone: true,
        })
      }
    } catch (err) {
      console.error(`❌ STREAK_MILESTONE broadcast error: ${err.message}`)
    }
  })
}