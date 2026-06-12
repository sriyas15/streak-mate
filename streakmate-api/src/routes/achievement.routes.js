import { achievementController } from '../controllers/achievement.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const achievementRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/', { handler: achievementController.getAllAchievements })
  fastify.get('/unlocked', { handler: achievementController.getUnlocked })
  fastify.get('/locked', { handler: achievementController.getLocked })
  fastify.get('/recent', { handler: achievementController.getRecent })
  fastify.patch('/:achievementId/seen', { handler: achievementController.markSeen })
}