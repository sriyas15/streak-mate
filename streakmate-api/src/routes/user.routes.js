import { userController } from '../controllers/user.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const userRoutes = async (fastify) => {
    // all user routes require auth
    fastify.addHook('preHandler', authenticate)

    // ─── Profile ──────────────────────────────────────────────────
    fastify.get('/profile', { handler: userController.getProfile })
    fastify.patch('/profile', { handler: userController.updateProfile })
    fastify.delete('/account', { handler: userController.deleteAccount })

    // ─── Avatar ───────────────────────────────────────────────────
    fastify.post('/profile/picture', { handler: userController.uploadProfilePicture })
    fastify.delete('/profile/picture', { handler: userController.deleteProfilePicture })

    // ─── Settings ─────────────────────────────────────────────────
    fastify.get('/settings', { handler: userController.getSettings })
    fastify.patch('/settings', { handler: userController.updateSettings })

    // ─── Timezone ─────────────────────────────────────────────────
    fastify.patch('/timezone', { handler: userController.updateTimezone })

    // ─── Public profile (other users) ────────────────────────────
    fastify.get('/:userId/profile', { handler: userController.getPublicProfile })
    fastify.get('/:userId/stats', { handler: userController.getUserStats })
}