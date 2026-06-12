import { appConfigController } from '../controllers/appConfig.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const appConfigRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/app', { handler: appConfigController.getAppConfig })
  fastify.get('/habit-templates', { handler: appConfigController.getHabitTemplates })
  fastify.get('/notification-templates', { handler: appConfigController.getNotificationTemplates })
}