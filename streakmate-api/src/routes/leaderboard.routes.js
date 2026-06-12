import { leaderboardController } from '../controllers/leaderboard.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const leaderboardRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/friends', { handler: leaderboardController.getFriendsLeaderboard })
  fastify.get('/friends/weekly', { handler: leaderboardController.getFriendsWeeklyLeaderboard })
  fastify.get('/global', { handler: leaderboardController.getGlobalLeaderboard })
  fastify.get('/category/:category', { handler: leaderboardController.getCategoryLeaderboard })
}