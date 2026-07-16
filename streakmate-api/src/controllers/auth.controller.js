import { authService } from '../services/auth.service.js'

export const authController = {
  // POST /auth/register
  register: async (req, reply) => {
    const { name, username, email, password, timezone } = req.body
    const result = await authService.register({ name, username, email, password, timezone })
    return reply.code(201).send({
      success: true,
      message: 'Account created. Please verify your email.',
      data: result,
    })
  },

  // POST /auth/login
  login: async (req, reply) => {
    const { email, password, timezone } = req.body
    const result = await authService.login({ email, password, timezone })
    return reply.send({
      success: true,
      message: 'Login successful',
      data: result,
    })
  },

  // auth.controller.js
  updateTimezone: async (req, reply) => {
    const { timezone } = req.body
    const user = await authService.updateTimezone(req.user._id, timezone)
    return reply.send({ success: true, data: { user } })
  },

  // POST /auth/logout
  logout: async (req, reply) => {
    await authService.logout(req.user._id)
    return reply.send({ success: true, message: 'Logged out successfully' })
  },

  // POST /auth/refresh-token
  refreshToken: async (req, reply) => {
    const { refreshToken } = req.body
    if (!refreshToken) {
      return reply.code(400).send({ success: false, message: 'Refresh token is required' })
    }
    const result = await authService.refreshToken(refreshToken)
    return reply.send({ success: true, data: result })
  },

  // POST /auth/forgot-password
  forgotPassword: async (req, reply) => {
    const { email } = req.body
    await authService.forgotPassword(email)
    // Always return success to prevent email enumeration
    return reply.send({
      success: true,
      message: 'If that email exists, a reset link has been sent.',
    })
  },

  // POST /auth/reset-password
  resetPassword: async (req, reply) => {
    const { token, newPassword } = req.body
    await authService.resetPassword({ token, newPassword })
    return reply.send({ success: true, message: 'Password reset successfully' })
  },

  // POST /auth/verify-email
  verifyEmail: async (req, reply) => {
    const { token } = req.body
    await authService.verifyEmail(token)
    return reply.send({ success: true, message: 'Email verified successfully' })
  },

  // POST /auth/resend-verification
  resendVerification: async (req, reply) => {
    await authService.resendVerification(req.user._id)
    return reply.send({ success: true, message: 'Verification email sent' })
  },

  // POST /auth/google
  googleAuth: async (req, reply) => {
    const { idToken } = req.body
    const result = await authService.googleAuth(idToken)
    return reply.send({ success: true, data: result })
  },

  // POST /auth/apple
  appleAuth: async (req, reply) => {
    const { idToken, fullName } = req.body
    const result = await authService.appleAuth({ idToken, fullName })
    return reply.send({ success: true, data: result })
  },

  // GET /auth/me
  getMe: async (req, reply) => {
    return reply.send({ success: true, data: { user: req.user } })
  },
}