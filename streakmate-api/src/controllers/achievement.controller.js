import { achievementService } from '../services/achievement.service.js'

export const achievementController = {
  // GET /achievements
  getAllAchievements: async (req, reply) => {
    const achievements = await achievementService.getAllAchievements(req.user._id)
    return reply.send({ success: true, data: { achievements } })
  },

  // GET /achievements/unlocked
  getUnlocked: async (req, reply) => {
    const achievements = await achievementService.getUnlocked(req.user._id)
    return reply.send({ success: true, data: { achievements } })
  },

  // GET /achievements/locked
  getLocked: async (req, reply) => {
    const achievements = await achievementService.getLocked(req.user._id)
    return reply.send({ success: true, data: { achievements } })
  },

  // GET /achievements/recent
  getRecent: async (req, reply) => {
    const achievements = await achievementService.getRecent(req.user._id)
    return reply.send({ success: true, data: { achievements } })
  },

  // PATCH /achievements/:achievementId/seen
  markSeen: async (req, reply) => {
    await achievementService.markSeen(req.user._id, req.params.achievementId)
    return reply.send({ success: true, message: 'Achievement marked as seen' })
  },
}