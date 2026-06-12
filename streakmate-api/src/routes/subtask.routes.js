import { subtaskController } from '../controllers/subtask.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const subtaskRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/:habitId/subtasks', { handler: subtaskController.getSubtasks })
  fastify.post('/:habitId/subtasks', { handler: subtaskController.createSubtask })
  fastify.patch('/:habitId/subtasks/:subtaskId', { handler: subtaskController.updateSubtask })
  fastify.delete('/:habitId/subtasks/:subtaskId', { handler: subtaskController.deleteSubtask })
  fastify.patch('/:habitId/subtasks/reorder', { handler: subtaskController.reorderSubtasks })
}