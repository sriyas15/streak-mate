import { leaderboardService } from '../services/leaderboard.service.js'

export const leaderboardController = {
  // GET /leaderboard/friends
  getFriendsLeaderboard: async (req, reply) => {
    const leaderboard = await leaderboardService.getFriendsLeaderboard(req.user._id)
    return reply.send({ success: true, data: { leaderboard } })
  },

  // GET /leaderboard/friends/weekly
  getFriendsWeeklyLeaderboard: async (req, reply) => {
    const leaderboard = await leaderboardService.getFriendsWeeklyLeaderboard(req.user._id)
    return reply.send({ success: true, data: { leaderboard } })
  },

  // GET /leaderboard/global
  getGlobalLeaderboard: async (req, reply) => {
    const { page = 1, limit = 50 } = req.query
    const leaderboard = await leaderboardService.getGlobalLeaderboard({ page, limit })
    return reply.send({ success: true, data: { leaderboard } })
  },

  // GET /leaderboard/category/:category
  getCategoryLeaderboard: async (req, reply) => {
    const leaderboard = await leaderboardService.getCategoryLeaderboard(
      req.user._id,
      req.params.category
    )
    return reply.send({ success: true, data: { leaderboard } })
  },
}