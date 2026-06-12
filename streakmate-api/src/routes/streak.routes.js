import { streakController } from '../controllers/streak.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const streakRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/overall', { handler: streakController.getOverallStreak })
  fastify.get('/overall/history', { handler: streakController.getOverallHistory })
  fastify.get('/summary', { handler: streakController.getStreakSummary })
  fastify.get('/milestones', { handler: streakController.getMilestones })
  fastify.get('/rank', { handler: streakController.getFriendRank })
  fastify.get('/habits/:habitId', { handler: streakController.getHabitStreak })
  fastify.get('/habits/:habitId/history', { handler: streakController.getHabitStreakHistory })
}