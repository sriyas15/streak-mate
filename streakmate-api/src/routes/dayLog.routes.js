import { dayLogController } from '../controllers/dayLog.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const dayLogRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/today', { handler: dayLogController.getToday })
  fastify.get('/range', { handler: dayLogController.getRange })
  fastify.get('/calendar', { handler: dayLogController.getCalendar })
  fastify.get('/:date', { handler: dayLogController.getByDate })
  fastify.patch('/:date/mood', { handler: dayLogController.updateMood })
  fastify.patch('/:date/note', { handler: dayLogController.updateNote })

  // ─── Freeze / Cheat ───────────────────────────────────────────
  fastify.post('/:date/freeze', { handler: dayLogController.activateFreeze })
  fastify.post('/:date/cheat-day', { handler: dayLogController.activateCheatDay })
  fastify.delete('/:date/freeze', { handler: dayLogController.undoFreeze })
}