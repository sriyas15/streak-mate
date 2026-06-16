import { calendarService } from '../services/calendar.service.js'

export const calendarController = {
  // GET /calendar/month?month=2024-06
  getMonth: async (req, reply) => {
    const { month } = req.query
    const calendar = await calendarService.getMonth(req.user._id, month)
    return reply.send({ success: true, data: { calendar } })
  },

  // GET /calendar/day/:date
  getDay: async (req, reply) => {
    const day = await calendarService.getDay(req.user._id, req.params.date)
    return reply.send({ success: true, data: { day } })
  },

  // GET /calendar/streak-map
  getStreakMap: async (req, reply) => {
    const streakMap = await calendarService.getStreakMap(req.user._id)
    return reply.send({ success: true, data: { streakMap } })
  },
}