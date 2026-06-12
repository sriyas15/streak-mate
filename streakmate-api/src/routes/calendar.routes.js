import { calendarController } from '../controllers/calendar.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const calendarRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/month', { handler: calendarController.getMonth })
  fastify.get('/day/:date', { handler: calendarController.getDay })
  fastify.get('/streak-map', { handler: calendarController.getStreakMap })
}