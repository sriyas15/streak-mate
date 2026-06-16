import { User, FriendRequest } from '../models/index.js'
import { Streak, HabitLog } from '../models/index.js'
import { notificationService } from './notification.service.js'
import { emitToUser, SOCKET_EVENTS } from '../config/socket.js'
import { getTodayDate } from '../utils/dateHelper.js'

export const friendsService = {
  // ── Get friends list ─────────────────────────────────────────────
  getFriends: async (userId) => {
    const user = await User.findById(userId).select('friendIds').lean()
    return User.find({ _id: { $in: user.friendIds } })
      .select('name username profilePicture currentStreakDays bestStreakDays level')
      .lean()
  },

  // ── Search users ─────────────────────────────────────────────────
  searchUsers: async (userId, query) => {
    if (!query || query.length < 2) return []

    const user = await User.findById(userId).select('friendIds friendRequestsSent').lean()

    const users = await User.find({
      $or: [
        { username: { $regex: query, $options: 'i' } },
        { name: { $regex: query, $options: 'i' } },
      ],
      _id: { $ne: userId },
      isActive: true,
    })
      .select('name username profilePicture currentStreakDays level')
      .limit(20)
      .lean()

    return users.map((u) => ({
      ...u,
      isFriend: user.friendIds.map(String).includes(String(u._id)),
      requestSent: user.friendRequestsSent.map(String).includes(String(u._id)),
    }))
  },

  // ── Friend suggestions ───────────────────────────────────────────
  getSuggestions: async (userId) => {
    const user = await User.findById(userId).select('friendIds friendRequestsSent').lean()
    const excludeIds = [userId, ...user.friendIds, ...user.friendRequestsSent]

    return User.find({ _id: { $nin: excludeIds }, isActive: true })
      .select('name username profilePicture currentStreakDays level')
      .sort({ currentStreakDays: -1 })
      .limit(10)
      .lean()
  },

  // ── Friends recent activity ──────────────────────────────────────
  getFriendsActivity: async (userId) => {
    const user = await User.findById(userId).select('friendIds').lean()
    const today = getTodayDate()

    const logs = await HabitLog.find({
      userId: { $in: user.friendIds },
      date: today,
      isCompleted: true,
    })
      .populate('userId', 'name username profilePicture')
      .populate('habitId', 'name icon category')
      .sort({ completedAt: -1 })
      .limit(20)
      .lean()

    return logs
  },

  // ── Get incoming requests ────────────────────────────────────────
  getIncomingRequests: async (userId) => {
    return FriendRequest.find({ receiverId: userId, status: 'pending' })
      .populate('senderId', 'name username profilePicture currentStreakDays')
      .sort({ sentAt: -1 })
      .lean()
  },

  // ── Get sent requests ────────────────────────────────────────────
  getSentRequests: async (userId) => {
    return FriendRequest.find({ senderId: userId, status: 'pending' })
      .populate('receiverId', 'name username profilePicture')
      .sort({ sentAt: -1 })
      .lean()
  },

  // ── Send friend request ──────────────────────────────────────────
  sendRequest: async (userId, targetUserId) => {
    if (String(userId) === String(targetUserId)) throwBadRequest('Cannot add yourself')

    const target = await User.findById(targetUserId)
    if (!target) throwNotFound('User')

    const user = await User.findById(userId).select('friendIds').lean()
    if (user.friendIds.map(String).includes(String(targetUserId))) {
      throwBadRequest('Already friends')
    }

    const existing = await FriendRequest.findOne({
      senderId: userId,
      receiverId: targetUserId,
      status: 'pending',
    })
    if (existing) throwBadRequest('Request already sent')

    await FriendRequest.create({ senderId: userId, receiverId: targetUserId })

    await User.findByIdAndUpdate(userId, { $addToSet: { friendRequestsSent: targetUserId } })
    await User.findByIdAndUpdate(targetUserId, { $addToSet: { friendRequestsReceived: userId } })

    // Notify target
    await notificationService.sendToUser(targetUserId, {
      type: 'friend_request',
      title: 'New Friend Request',
      body: `${(await User.findById(userId).select('name').lean()).name} sent you a friend request`,
      deepLinkScreen: 'Friends',
    })

    emitToUser(targetUserId, SOCKET_EVENTS.FRIEND_REQUEST_RECEIVED, { fromUserId: userId })
  },

  // ── Cancel request ───────────────────────────────────────────────
  cancelRequest: async (userId, targetUserId) => {
    await FriendRequest.findOneAndUpdate(
      { senderId: userId, receiverId: targetUserId, status: 'pending' },
      { status: 'cancelled' }
    )
    await User.findByIdAndUpdate(userId, { $pull: { friendRequestsSent: targetUserId } })
    await User.findByIdAndUpdate(targetUserId, { $pull: { friendRequestsReceived: userId } })
  },

  // ── Accept request ───────────────────────────────────────────────
  acceptRequest: async (userId, requesterId) => {
    const request = await FriendRequest.findOne({
      senderId: requesterId,
      receiverId: userId,
      status: 'pending',
    })
    if (!request) throwNotFound('Friend request')

    await request.updateOne({ status: 'accepted', respondedAt: new Date() })

    // Add each other as friends
    await Promise.all([
      User.findByIdAndUpdate(userId, {
        $addToSet: { friendIds: requesterId },
        $pull: { friendRequestsReceived: requesterId },
      }),
      User.findByIdAndUpdate(requesterId, {
        $addToSet: { friendIds: userId },
        $pull: { friendRequestsSent: userId },
      }),
    ])

    const acceptingUser = await User.findById(userId).select('name').lean()

    await notificationService.sendToUser(requesterId, {
      type: 'friend_accepted',
      title: 'Friend Request Accepted 🎉',
      body: `${acceptingUser.name} accepted your friend request`,
      deepLinkScreen: 'Friends',
    })

    emitToUser(requesterId, SOCKET_EVENTS.FRIEND_ACCEPTED, { userId })
  },

  // ── Reject request ───────────────────────────────────────────────
  rejectRequest: async (userId, requesterId) => {
    await FriendRequest.findOneAndUpdate(
      { senderId: requesterId, receiverId: userId, status: 'pending' },
      { status: 'rejected', respondedAt: new Date() }
    )
    await User.findByIdAndUpdate(userId, { $pull: { friendRequestsReceived: requesterId } })
    await User.findByIdAndUpdate(requesterId, { $pull: { friendRequestsSent: userId } })
  },

  // ── Remove friend ────────────────────────────────────────────────
  removeFriend: async (userId, friendId) => {
    await Promise.all([
      User.findByIdAndUpdate(userId, { $pull: { friendIds: friendId } }),
      User.findByIdAndUpdate(friendId, { $pull: { friendIds: userId } }),
    ])
  },

  // ── Get friend's public streak data ─────────────────────────────
  getFriendStreaks: async (userId, friendId) => {
    const user = await User.findById(userId).select('friendIds').lean()
    if (!user.friendIds.map(String).includes(String(friendId))) {
      throwBadRequest('Not friends with this user')
    }

    const [friend, streaks] = await Promise.all([
      User.findById(friendId)
        .select('name username profilePicture currentStreakDays bestStreakDays level')
        .lean(),
      Streak.find({ userId: friendId }).lean(),
    ])

    return { friend, streaks }
  },

  // ── Nudge a friend ───────────────────────────────────────────────
  nudgeFriend: async (userId, friendId) => {
    const user = await User.findById(userId).select('name friendIds').lean()
    if (!user.friendIds.map(String).includes(String(friendId))) {
      throwBadRequest('Not friends with this user')
    }

    await notificationService.sendToUser(friendId, {
      type: 'friend_nudge',
      title: 'Nudge from a friend 👊',
      body: `${user.name} is checking if you did your habits today!`,
      deepLinkScreen: 'Home',
    })

    emitToUser(friendId, SOCKET_EVENTS.RECEIVE_NUDGE, { from: { userId, name: user.name } })
  },
}

const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}

const throwBadRequest = (message) => {
  const err = new Error(message)
  err.statusCode = 400
  throw err
}