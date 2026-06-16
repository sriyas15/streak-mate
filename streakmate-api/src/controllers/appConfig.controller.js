import { appConfigService } from '../services/appConfig.service.js'

export const appConfigController = {
  // GET /config/app
  getAppConfig: async (req, reply) => {
    const config = await appConfigService.getAppConfig()
    return reply.send({ success: true, data: { config } })
  },

  // GET /config/habit-templates
  getHabitTemplates: async (req, reply) => {
    const templates = await appConfigService.getHabitTemplates()
    return reply.send({ success: true, data: { templates } })
  },

  // GET /config/notification-templates
  getNotificationTemplates: async (req, reply) => {
    const templates = await appConfigService.getNotificationTemplates()
    return reply.send({ success: true, data: { templates } })
  },
}