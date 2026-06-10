import { authController } from '../controllers/auth.controller.js'
import { authenticate } from '../middleware/authenticate.js'
import {
  registerSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  verifyEmailSchema,
} from '../validators/auth.validator.js'

export const authRoutes = async (fastify) => {
  // ─── Public routes ────────────────────────────────────────────
  fastify.post('/register', {
    schema: { body: registerSchema },
    handler: authController.register,
  })

  fastify.post('/login', {
    schema: { body: loginSchema },
    handler: authController.login,
  })

  fastify.post('/refresh-token', {
    handler: authController.refreshToken,
  })

  fastify.post('/forgot-password', {
    schema: { body: forgotPasswordSchema },
    handler: authController.forgotPassword,
  })

  fastify.post('/reset-password', {
    schema: { body: resetPasswordSchema },
    handler: authController.resetPassword,
  })

  fastify.post('/verify-email', {
    schema: { body: verifyEmailSchema },
    handler: authController.verifyEmail,
  })

  fastify.post('/resend-verification', {
    preHandler: [authenticate],
    handler: authController.resendVerification,
  })

  // ─── OAuth ────────────────────────────────────────────────────
  fastify.post('/google', {
    handler: authController.googleAuth,
  })

  fastify.post('/apple', {
    handler: authController.appleAuth,
  })

  // ─── Protected routes ─────────────────────────────────────────
  fastify.get('/me', {
    preHandler: [authenticate],
    handler: authController.getMe,
  })

  fastify.post('/logout', {
    preHandler: [authenticate],
    handler: authController.logout,
  })
}