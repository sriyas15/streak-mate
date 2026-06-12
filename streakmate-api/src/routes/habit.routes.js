import { habitController } from '../controllers/habit.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const habitRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  // ─── Templates (before /:habitId to avoid param clash) ───────
  fastify.get('/templates', { handler: habitController.getTemplates })
  fastify.get('/templates/:category', { handler: habitController.getTemplatesByCategory })

  // ─── Today ────────────────────────────────────────────────────
  fastify.get('/today', { handler: habitController.getTodayHabits })

  // ─── CRUD ─────────────────────────────────────────────────────
  fastify.get('/', { handler: habitController.getAllHabits })
  fastify.post('/', { handler: habitController.createHabit })
  fastify.get('/:habitId', { handler: habitController.getHabit })
  fastify.patch('/:habitId', { handler: habitController.updateHabit })
  fastify.delete('/:habitId', { handler: habitController.deleteHabit })

  // ─── State ────────────────────────────────────────────────────
  fastify.patch('/:habitId/archive', { handler: habitController.archiveHabit })
  fastify.patch('/:habitId/restore', { handler: habitController.restoreHabit })
  fastify.patch('/:habitId/reorder', { handler: habitController.reorderHabit })

  // ─── Completion rule ──────────────────────────────────────────
  fastify.patch('/:habitId/completion-rule', { handler: habitController.updateCompletionRule })
}