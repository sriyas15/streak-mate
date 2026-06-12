import { onboardingService } from '../services/onboarding.service.js'

export const onboardingController = {
  // GET /onboarding/status
  getStatus: async (req, reply) => {
    const status = await onboardingService.getStatus(req.user._id)
    return reply.send({ success: true, data: { status } })
  },

  // POST /onboarding/goal  body: { selectedGoal }
  setGoal: async (req, reply) => {
    const { selectedGoal } = req.body
    await onboardingService.setGoal(req.user._id, selectedGoal)
    return reply.send({ success: true, message: 'Goal saved', data: { step: 2 } })
  },

  // POST /onboarding/habits  body: { categories: [] }
  selectHabits: async (req, reply) => {
    const { categories } = req.body
    const habits = await onboardingService.selectHabits(req.user._id, categories)
    return reply.send({ success: true, message: 'Habits created', data: { habits, step: 3 } })
  },

  // POST /onboarding/subtasks  body: { habitSubtasks: [{ habitId, subtaskIds }] }
  configureSubtasks: async (req, reply) => {
    const { habitSubtasks } = req.body
    await onboardingService.configureSubtasks(req.user._id, habitSubtasks)
    return reply.send({ success: true, message: 'Subtasks configured', data: { step: 4 } })
  },

  // POST /onboarding/reminders  body: { reminders: [{ habitId, times[] }] }
  setReminders: async (req, reply) => {
    const { reminders } = req.body
    await onboardingService.setReminders(req.user._id, reminders)
    return reply.send({ success: true, message: 'Reminders set', data: { step: 5 } })
  },

  // POST /onboarding/complete
  complete: async (req, reply) => {
    const result = await onboardingService.complete(req.user._id)
    return reply.send({
      success: true,
      message: "You're all set! Let's build some streaks 🔥",
      data: result,
    })
  },
}