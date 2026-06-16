import { gamificationService } from '../services/gamification.service.js'

export const gamificationController = {
  // GET /gamification/level
  getLevel: async (req, reply) => {
    const level = await gamificationService.getLevel(req.user._id)
    return reply.send({ success: true, data: { level } })
  },

  // GET /gamification/xp-history
  getXPHistory: async (req, reply) => {
    const { page = 1, limit = 20 } = req.query
    const history = await gamificationService.getXPHistory(req.user._id, { page, limit })
    return reply.send({ success: true, data: { history } })
  },

  // GET /gamification/badges
  getBadges: async (req, reply) => {
    const badges = await gamificationService.getBadges(req.user._id)
    return reply.send({ success: true, data: { badges } })
  },
}