import { subtaskService } from '../services/subtask.service.js'

export const subtaskController = {
  // GET /habits/:habitId/subtasks
  getSubtasks: async (req, reply) => {
    const subtasks = await subtaskService.getSubtasks(req.user._id, req.params.habitId)
    return reply.send({ success: true, data: { subtasks } })
  },

  // POST /habits/:habitId/subtasks
  createSubtask: async (req, reply) => {
    const subtask = await subtaskService.createSubtask(req.user._id, req.params.habitId, req.body)
    return reply.code(201).send({ success: true, message: 'Subtask created', data: { subtask } })
  },

  // PATCH /habits/:habitId/subtasks/:subtaskId
  updateSubtask: async (req, reply) => {
    const subtask = await subtaskService.updateSubtask(
      req.user._id,
      req.params.habitId,
      req.params.subtaskId,
      req.body
    )
    return reply.send({ success: true, message: 'Subtask updated', data: { subtask } })
  },

  // DELETE /habits/:habitId/subtasks/:subtaskId
  deleteSubtask: async (req, reply) => {
    await subtaskService.deleteSubtask(req.user._id, req.params.habitId, req.params.subtaskId)
    return reply.send({ success: true, message: 'Subtask deleted' })
  },

  // PATCH /habits/:habitId/subtasks/reorder
  reorderSubtasks: async (req, reply) => {
    // body: { order: [{ subtaskId, displayOrder }] }
    await subtaskService.reorderSubtasks(req.user._id, req.params.habitId, req.body.order)
    return reply.send({ success: true, message: 'Subtasks reordered' })
  },
}