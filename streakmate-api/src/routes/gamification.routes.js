import { gamificationController } from '../controllers/gamification.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const gamificationRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/level', { handler: gamificationController.getLevel })
  fastify.get('/xp-history', { handler: gamificationController.getXPHistory })
  fastify.get('/badges', { handler: gamificationController.getBadges })
}