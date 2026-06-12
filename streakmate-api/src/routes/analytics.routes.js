import { analyticsController } from '../controllers/analytics.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const analyticsRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/overview', { handler: analyticsController.getOverview })
  fastify.get('/productive-days', { handler: analyticsController.getProductiveDays })
  fastify.get('/categories', { handler: analyticsController.getCategoryPerformance })
  fastify.get('/weekly-summary', { handler: analyticsController.getWeeklySummary })
  fastify.get('/monthly-report', { handler: analyticsController.getMonthlyReport })
  fastify.get('/insights', { handler: analyticsController.getInsights })
  fastify.get('/heatmap', { handler: analyticsController.getHeatmap })
  fastify.get('/habits/:habitId', { handler: analyticsController.getHabitAnalytics })
}