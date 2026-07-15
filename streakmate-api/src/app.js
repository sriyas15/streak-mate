import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import {
  validatorCompiler,
  serializerCompiler,
} from 'fastify-type-provider-zod'

import { env } from './config/env.js'
import { registerRoutes } from './routes/index.js'
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

  fastify.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
    if (!body || body.length === 0) {
      done(null, {})
      return
    }
    try {
      done(null, JSON.parse(body))
    } catch (err) {
      err.statusCode = 400
      done(err, undefined)
    }
  })

  // API routes
  fastify.register(registerRoutes, {
    prefix: `/api/${env.API_VERSION}`,
})

  // 404 handler
  fastify.setNotFoundHandler(notFoundHandler)

  // Global error handler
  fastify.setErrorHandler(errorHandler)

  return fastify
}

export default buildApp