import { habitLogController } from '../controllers/habitLog.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const habitLogRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  // ─── Log CRUD ─────────────────────────────────────────────────
  fastify.post('/:habitId/logs', { handler: habitLogController.createLog })
  fastify.get('/:habitId/logs', { handler: habitLogController.getLogs })
  fastify.get('/:habitId/logs/range', { handler: habitLogController.getLogsInRange })
  fastify.get('/:habitId/logs/:date', { handler: habitLogController.getLogByDate })
  fastify.patch('/:habitId/logs/:date', { handler: habitLogController.updateLog })

  // ─── Subtask completion ───────────────────────────────────────
  fastify.patch(
    '/:habitId/logs/:date/subtasks/:subtaskId',
    { handler: habitLogController.updateSubtaskResult }
  )

  // ─── Mark complete / uncomplete ───────────────────────────────
  fastify.post('/:habitId/logs/:date/complete', { handler: habitLogController.markComplete })
  fastify.post('/:habitId/logs/:date/uncomplete', { handler: habitLogController.markUncomplete })
}