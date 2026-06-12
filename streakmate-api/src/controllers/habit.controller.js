import { habitService } from '../services/habit.service.js'

export const habitController = {
  // GET /habits
  getAllHabits: async (req, reply) => {
    const habits = await habitService.getAllHabits(req.user._id, req.query)
    return reply.send({ success: true, data: { habits } })
  },

  // POST /habits
  createHabit: async (req, reply) => {
    const habit = await habitService.createHabit(req.user._id, req.body)
    return reply.code(201).send({ success: true, message: 'Habit created', data: { habit } })
  },

  // GET /habits/:habitId
  getHabit: async (req, reply) => {
    const habit = await habitService.getHabit(req.user._id, req.params.habitId)
    return reply.send({ success: true, data: { habit } })
  },

  // PATCH /habits/:habitId
  updateHabit: async (req, reply) => {
    const habit = await habitService.updateHabit(req.user._id, req.params.habitId, req.body)
    return reply.send({ success: true, message: 'Habit updated', data: { habit } })
  },

  // DELETE /habits/:habitId
  deleteHabit: async (req, reply) => {
    await habitService.deleteHabit(req.user._id, req.params.habitId)
    return reply.send({ success: true, message: 'Habit deleted' })
  },

  // PATCH /habits/:habitId/archive
  archiveHabit: async (req, reply) => {
    await habitService.archiveHabit(req.user._id, req.params.habitId)
    return reply.send({ success: true, message: 'Habit archived' })
  },

  // PATCH /habits/:habitId/restore
  restoreHabit: async (req, reply) => {
    await habitService.restoreHabit(req.user._id, req.params.habitId)
    return reply.send({ success: true, message: 'Habit restored' })
  },

  // PATCH /habits/:habitId/reorder
  reorderHabit: async (req, reply) => {
    const { displayOrder } = req.body
    await habitService.reorderHabit(req.user._id, req.params.habitId, displayOrder)
    return reply.send({ success: true, message: 'Order updated' })
  },

  // PATCH /habits/:habitId/completion-rule
  updateCompletionRule: async (req, reply) => {
    const { completionRule, completionThreshold } = req.body
    const habit = await habitService.updateCompletionRule(
      req.user._id,
      req.params.habitId,
      { completionRule, completionThreshold }
    )
    return reply.send({ success: true, message: 'Completion rule updated', data: { habit } })
  },

  // GET /habits/templates
  getTemplates: async (req, reply) => {
    const templates = await habitService.getTemplates()
    return reply.send({ success: true, data: { templates } })
  },

  // GET /habits/templates/:category
  getTemplatesByCategory: async (req, reply) => {
    const templates = await habitService.getTemplatesByCategory(req.params.category)
    return reply.send({ success: true, data: { templates } })
  },

  // GET /habits/today
  getTodayHabits: async (req, reply) => {
    const habits = await habitService.getTodayHabits(req.user._id)
    return reply.send({ success: true, data: { habits } })
  },
}