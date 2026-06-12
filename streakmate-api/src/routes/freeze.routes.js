import { freezeController } from '../controllers/freeze.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const freezeRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/balance', { handler: freezeController.getBalance })
  fastify.post('/activate', { handler: freezeController.activateFreeze })
  fastify.post('/cheat-day/activate', { handler: freezeController.activateCheatDay })
  fastify.get('/history', { handler: freezeController.getHistory })
}