import { env } from '../config/env.js'

/**
 * Logger config for Fastify
 * Passed into Fastify({ logger: loggerConfig })
 *
 * Dev: pretty-printed human-readable logs
 * Production: JSON structured logs (for Railway/Render log aggregators)
 */
export const loggerConfig = env.NODE_ENV === 'production'
  ? {
      level: 'info',
      serializers: {
        req(req) {
          return {
            method: req.method,
            url: req.url,
            userId: req.user?._id,
          }
        },
        res(res) {
          return { statusCode: res.statusCode }
        },
      },
    }
  : {
      level: 'debug',
      transport: {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss',
          ignore: 'pid,hostname',
        },
      },
    }

/**
 * requestLogger
 * Fastify onRequest hook — logs every incoming request
 * Registered globally in app.js
 */
export const requestLogger = async (req, reply) => {
  req.log.info({
    method: req.method,
    url: req.url,
    userId: req.user?._id?.toString() || 'anonymous',
    ip: req.ip,
  })
}

/**
 * responseLogger
 * Fastify onSend hook — logs response time
 */
export const responseLogger = async (req, reply, payload) => {
  req.log.info({
    method: req.method,
    url: req.url,
    statusCode: reply.statusCode,
    responseTime: reply.getResponseTime?.().toFixed(2) + 'ms',
  })
  return payload
}