import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import {
  validatorCompiler,
  serializerCompiler,
} from 'fastify-type-provider-zod'

import { env } from './config/env.js'
import {authRoutes} from './routes/auth.routes.js'
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js'

const buildApp = async () => {
  const fastify = Fastify({
    logger: true,
  })

  fastify.setValidatorCompiler(validatorCompiler)
  fastify.setSerializerCompiler(serializerCompiler)

  // Plugins
  await fastify.register(cors, {
    origin: true,
    credentials: true,
  })

  await fastify.register(helmet, {
    contentSecurityPolicy: false,
  })

  // Health check
  fastify.get('/health', async () => {
    return {
      status: 'ok',
      env: env.NODE_ENV,
      timestamp: new Date().toISOString(),
    }
  })

  // API routes
  fastify.register(
    async (v1) => {
      v1.register(authRoutes, {
        prefix: '/auth',
      })
    },
    {
      prefix: `/api/${env.API_VERSION}`,
    }
  )

  // 404 handler
  fastify.setNotFoundHandler(notFoundHandler)

  // Global error handler
  fastify.setErrorHandler(errorHandler)

  return fastify
}

export default buildApp