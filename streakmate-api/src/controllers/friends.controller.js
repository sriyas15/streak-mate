import { friendsService } from '../services/friends.service.js'

export const friendsController = {
  // GET /friends
  getFriends: async (req, reply) => {
    const friends = await friendsService.getFriends(req.user._id)
    return reply.send({ success: true, data: { friends } })
  },

  // GET /friends/search?q=username
  searchUsers: async (req, reply) => {
    const { q } = req.query
    const users = await friendsService.searchUsers(req.user._id, q)
    return reply.send({ success: true, data: { users } })
  },

  // GET /friends/suggestions
  getSuggestions: async (req, reply) => {
    const suggestions = await friendsService.getSuggestions(req.user._id)
    return reply.send({ success: true, data: { suggestions } })
  },

  // GET /friends/activity
  getFriendsActivity: async (req, reply) => {
    const activity = await friendsService.getFriendsActivity(req.user._id)
    return reply.send({ success: true, data: { activity } })
  },

  // GET /friends/requests
  getIncomingRequests: async (req, reply) => {
    const requests = await friendsService.getIncomingRequests(req.user._id)
    return reply.send({ success: true, data: { requests } })
  },

  // GET /friends/requests/sent
  getSentRequests: async (req, reply) => {
    const requests = await friendsService.getSentRequests(req.user._id)
    return reply.send({ success: true, data: { requests } })
  },

  // POST /friends/request/:userId
  sendRequest: async (req, reply) => {
    await friendsService.sendRequest(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Friend request sent' })
  },

  // DELETE /friends/request/:userId
  cancelRequest: async (req, reply) => {
    await friendsService.cancelRequest(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Request cancelled' })
  },

  // POST /friends/accept/:userId
  acceptRequest: async (req, reply) => {
    await friendsService.acceptRequest(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Friend request accepted' })
  },

  // POST /friends/reject/:userId
  rejectRequest: async (req, reply) => {
    await friendsService.rejectRequest(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Friend request rejected' })
  },

  // DELETE /friends/:userId
  removeFriend: async (req, reply) => {
    await friendsService.removeFriend(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Friend removed' })
  },

  // GET /friends/:userId/streaks
  getFriendStreaks: async (req, reply) => {
    const streaks = await friendsService.getFriendStreaks(req.user._id, req.params.userId)
    return reply.send({ success: true, data: { streaks } })
  },

  // POST /friends/:userId/nudge
  nudgeFriend: async (req, reply) => {
    await friendsService.nudgeFriend(req.user._id, req.params.userId)
    return reply.send({ success: true, message: 'Nudge sent 👊' })
  },
}