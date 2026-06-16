import { habitLogService } from '../services/habitLog.service.js'

export const habitLogController = {
  // POST /habits/:habitId/logs
  createLog: async (req, reply) => {
    const log = await habitLogService.createLog(req.user._id, req.params.habitId, req.body)
    return reply.code(201).send({ success: true, message: 'Log created', data: { log } })
  },

  // GET /habits/:habitId/logs
  getLogs: async (req, reply) => {
    const { page = 1, limit = 30 } = req.query
    const result = await habitLogService.getLogs(req.user._id, req.params.habitId, { page, limit })
    return reply.send({ success: true, data: result })
  },

  // GET /habits/:habitId/logs/range
  getLogsInRange: async (req, reply) => {
    const { from, to } = req.query
    const logs = await habitLogService.getLogsInRange(req.user._id, req.params.habitId, { from, to })
    return reply.send({ success: true, data: { logs } })
  },

  // GET /habits/:habitId/logs/:date
  getLogByDate: async (req, reply) => {
    const log = await habitLogService.getLogByDate(
      req.user._id,
      req.params.habitId,
      req.params.date
    )
    return reply.send({ success: true, data: { log } })
  },

  // PATCH /habits/:habitId/logs/:date
  updateLog: async (req, reply) => {
    const log = await habitLogService.updateLog(
      req.user._id,
      req.params.habitId,
      req.params.date,
      req.body
    )
    return reply.send({ success: true, message: 'Log updated', data: { log } })
  },

  // PATCH /habits/:habitId/logs/:date/subtasks/:subtaskId
  updateSubtaskResult: async (req, reply) => {
    const { habitId, date, subtaskId } = req.params
    const log = await habitLogService.updateSubtaskResult(
      req.user._id,
      habitId,
      date,
      subtaskId,
      req.body // { isCompleted, value }
    )
    return reply.send({ success: true, message: 'Subtask updated', data: { log } })
  },

  // POST /habits/:habitId/logs/:date/complete
  markComplete: async (req, reply) => {
    const log = await habitLogService.markComplete(
      req.user._id,
      req.params.habitId,
      req.params.date
    )
    return reply.send({ success: true, message: 'Habit marked complete', data: { log } })
  },

  // POST /habits/:habitId/logs/:date/uncomplete
  markUncomplete: async (req, reply) => {
    const log = await habitLogService.markUncomplete(
      req.user._id,
      req.params.habitId,
      req.params.date
    )
    return reply.send({ success: true, message: 'Habit marked incomplete', data: { log } })
  },
}