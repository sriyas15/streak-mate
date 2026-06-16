import { streakService } from '../services/streak.service.js'

export const streakController = {
  // GET /streaks/overall
  getOverallStreak: async (req, reply) => {
    const streak = await streakService.getOverallStreak(req.user._id)
    return reply.send({ success: true, data: { streak } })
  },

  
  // GET /streaks/overall/history
  getOverallHistory: async (req, reply) => {
    const history = await streakService.getOverallHistory(req.user._id)
    return reply.send({ success: true, data: { history } })
  },

  // GET /streaks/summary
  getStreakSummary: async (req, reply) => {
    const summary = await streakService.getStreakSummary(req.user._id)
    return reply.send({ success: true, data: { summary } })
  },

  // GET /streaks/milestones
  getMilestones: async (req, reply) => {
    const milestones = await streakService.getMilestones(req.user._id)
    return reply.send({ success: true, data: { milestones } })
  },

  // GET /streaks/rank
  getFriendRank: async (req, reply) => {
    const rank = await streakService.getFriendRank(req.user._id)
    return reply.send({ success: true, data: { rank } })
  },

  // GET /streaks/habits/:habitId
  getHabitStreak: async (req, reply) => {
    const streak = await streakService.getHabitStreak(req.user._id, req.params.habitId)
    return reply.send({ success: true, data: { streak } })
  },

  // GET /streaks/habits/:habitId/history
  getHabitStreakHistory: async (req, reply) => {
    const history = await streakService.getHabitStreakHistory(req.user._id, req.params.habitId)
    return reply.send({ success: true, data: { history } })
  },
}