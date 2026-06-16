import { analyticsService } from '../services/analytics.service.js'

export const analyticsController = {
  // GET /analytics/overview?period=week|month|year
  getOverview: async (req, reply) => {
    const { period = 'week' } = req.query
    const overview = await analyticsService.getOverview(req.user._id, period)
    return reply.send({ success: true, data: { overview } })
  },

  // GET /analytics/productive-days?month=2024-06
  getProductiveDays: async (req, reply) => {
    const { month } = req.query
    const result = await analyticsService.getProductiveDays(req.user._id, month)
    return reply.send({ success: true, data: result })
  },

  // GET /analytics/categories?period=week|month|year
  getCategoryPerformance: async (req, reply) => {
    const { period = 'week' } = req.query
    const categories = await analyticsService.getCategoryPerformance(req.user._id, period)
    return reply.send({ success: true, data: { categories } })
  },

  // GET /analytics/weekly-summary
  getWeeklySummary: async (req, reply) => {
    const summary = await analyticsService.getWeeklySummary(req.user._id)
    return reply.send({ success: true, data: { summary } })
  },

  // GET /analytics/monthly-report?month=2024-06
  getMonthlyReport: async (req, reply) => {
    const { month } = req.query
    const report = await analyticsService.getMonthlyReport(req.user._id, month)
    return reply.send({ success: true, data: { report } })
  },

  // GET /analytics/insights
  getInsights: async (req, reply) => {
    const insights = await analyticsService.getInsights(req.user._id)
    return reply.send({ success: true, data: { insights } })
  },

  // GET /analytics/heatmap?year=2024
  getHeatmap: async (req, reply) => {
    const { year } = req.query
    const heatmap = await analyticsService.getHeatmap(req.user._id, year)
    return reply.send({ success: true, data: { heatmap } })
  },

  // GET /analytics/habits/:habitId
  getHabitAnalytics: async (req, reply) => {
    const { period = 'month' } = req.query
    const analytics = await analyticsService.getHabitAnalytics(
      req.user._id,
      req.params.habitId,
      period
    )
    return reply.send({ success: true, data: { analytics } })
  },
}