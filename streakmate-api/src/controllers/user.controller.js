import { userService } from '../services/user.service.js'

export const userController = {
  // GET /users/profile
  getProfile: async (req, reply) => {
    const user = await userService.getProfile(req.user._id)
    return reply.send({ success: true, data: { user } })
  },

  // PATCH /users/profile
  updateProfile: async (req, reply) => {
    const user = await userService.updateProfile(req.user._id, req.body)
    return reply.send({ success: true, message: 'Profile updated', data: { user } })
  },

  // DELETE /users/account
  deleteAccount: async (req, reply) => {
    await userService.deleteAccount(req.user._id)
    return reply.send({ success: true, message: 'Account deleted' })
  },

  // POST /users/profile/picture
  uploadProfilePicture: async (req, reply) => {
    const data = await req.file()
    const url = await userService.uploadProfilePicture(req.user._id, data)
    return reply.send({ success: true, data: { profilePicture: url } })
  },

  // DELETE /users/profile/picture
  deleteProfilePicture: async (req, reply) => {
    await userService.deleteProfilePicture(req.user._id)
    return reply.send({ success: true, message: 'Profile picture removed' })
  },

  // GET /users/settings
  getSettings: async (req, reply) => {
    const settings = await userService.getSettings(req.user._id)
    return reply.send({ success: true, data: { settings } })
  },

  // PATCH /users/settings
  updateSettings: async (req, reply) => {
    const settings = await userService.updateSettings(req.user._id, req.body)
    return reply.send({ success: true, message: 'Settings updated', data: { settings } })
  },

  // PATCH /users/timezone
  updateTimezone: async (req, reply) => {
    const { timezone } = req.body
    await userService.updateTimezone(req.user._id, timezone)
    return reply.send({ success: true, message: 'Timezone updated' })
  },

  // GET /users/:userId/profile
  getPublicProfile: async (req, reply) => {
    const user = await userService.getPublicProfile(req.params.userId, req.user._id)
    return reply.send({ success: true, data: { user } })
  },

  // GET /users/:userId/stats
  getUserStats: async (req, reply) => {
    const stats = await userService.getUserStats(req.params.userId)
    return reply.send({ success: true, data: { stats } })
  },
}