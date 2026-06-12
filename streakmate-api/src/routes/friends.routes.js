import { friendsController } from '../controllers/friends.controller.js'
import { authenticate } from '../middleware/authenticate.js'

export const friendsRoutes = async (fastify) => {
  fastify.addHook('preHandler', authenticate)

  // ─── My friends ───────────────────────────────────────────────
  fastify.get('/', { handler: friendsController.getFriends })
  fastify.get('/search', { handler: friendsController.searchUsers })
  fastify.get('/suggestions', { handler: friendsController.getSuggestions })
  fastify.get('/activity', { handler: friendsController.getFriendsActivity })

  // ─── Requests ─────────────────────────────────────────────────
  fastify.get('/requests', { handler: friendsController.getIncomingRequests })
  fastify.get('/requests/sent', { handler: friendsController.getSentRequests })
  fastify.post('/request/:userId', { handler: friendsController.sendRequest })
  fastify.delete('/request/:userId', { handler: friendsController.cancelRequest })
  fastify.post('/accept/:userId', { handler: friendsController.acceptRequest })
  fastify.post('/reject/:userId', { handler: friendsController.rejectRequest })

  // ─── Manage ───────────────────────────────────────────────────
  fastify.delete('/:userId', { handler: friendsController.removeFriend })

  // ─── Friend data ──────────────────────────────────────────────
  fastify.get('/:userId/streaks', { handler: friendsController.getFriendStreaks })
  fastify.post('/:userId/nudge', { handler: friendsController.nudgeFriend })
}