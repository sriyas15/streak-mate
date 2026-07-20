import { dayLogService } from '../services/dayLog.service.js'

export const dayLogController = {
  // GET /daylogs/today
  getToday: async (req, reply) => {
    const dayLog = await dayLogService.getToday(req.user._id)
    return reply.send({ success: true, data: { dayLog } })
  },

  // GET /daylogs/:date
  getByDate: async (req, reply) => {
    const dayLog = await dayLogService.getByDate(req.user._id, req.params.date)
    return reply.send({ success: true, data: { dayLog } })
  },

  // GET /daylogs/range?from=&to=
  getRange: async (req, reply) => {
    const { from, to } = req.query
    const dayLogs = await dayLogService.getRange(req.user._id, { from, to })
    return reply.send({ success: true, data: { dayLogs } })
  },

  // GET /daylogs/calendar?month=2024-06
  getCalendar: async (req, reply) => {
    const { month } = req.query
    const calendar = await dayLogService.getCalendar(req.user._id, month)
    return reply.send({ success: true, data: { calendar } })
  },

  // PATCH /daylogs/:date/mood
  updateMood: async (req, reply) => {
    const { mood } = req.body
    const dayLog = await dayLogService.updateMood(req.user._id, req.params.date, mood)
    return reply.send({ success: true, message: 'Mood updated', data: { dayLog } })
  },

  // PATCH /daylogs/:date/note
  updateNote: async (req, reply) => {
    const { note } = req.body
    const dayLog = await dayLogService.updateNote(req.user._id, req.params.date, note)
    return reply.send({ success: true, message: 'Note updated', data: { dayLog } })
  }
}