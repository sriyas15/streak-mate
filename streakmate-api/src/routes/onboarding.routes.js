import { onboardingController } from '../controllers/onboarding.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const onboardingRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  fastify.get('/status', { handler: onboardingController.getStatus })
  fastify.post('/goal', { handler: onboardingController.setGoal })
  fastify.post('/habits', { handler: onboardingController.selectHabits })
  fastify.post('/subtasks', { handler: onboardingController.configureSubtasks })
  fastify.post('/reminders', { handler: onboardingController.setReminders })
  fastify.post('/complete', { handler: onboardingController.complete })
}