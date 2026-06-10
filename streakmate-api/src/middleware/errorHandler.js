import { ZodError } from 'zod'
import { env } from '../config/env.js'

/**
 * Global Fastify error handler
 * Registered in app.js via fastify.setErrorHandler(errorHandler)
 *
 * Handles:
 * - Mongoose validation errors
 * - Mongoose cast errors (bad ObjectId)
 * - Mongoose duplicate key errors
 * - Zod validation errors
 * - Custom app errors (err.statusCode)
 * - JWT errors
 * - Generic 500 errors
 */
export const errorHandler = (err, req, reply) => {
  req.log.error({ err, url: req.url, method: req.method }, 'Request error')

  // ── Custom app errors (thrown manually with statusCode) ────────
  if (err.statusCode) {
    return reply.code(err.statusCode).send({
      success: false,
      message: err.message,
      code: err.code || codeFromStatus(err.statusCode),
    })
  }

  // ── Mongoose validation error ─────────────────────────────────
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }))
    return reply.code(422).send({
      success: false,
      message: 'Validation failed',
      code: 'VALIDATION_ERROR',
      errors,
    })
  }

  // ── Mongoose cast error (invalid ObjectId) ─────────────────────
  if (err.name === 'CastError') {
    return reply.code(400).send({
      success: false,
      message: `Invalid ${err.path}: ${err.value}`,
      code: 'INVALID_ID',
    })
  }

  // ── Mongoose duplicate key ─────────────────────────────────────
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field'
    return reply.code(409).send({
      success: false,
      message: `${capitalize(field)} already exists`,
      code: 'DUPLICATE_KEY',
    })
  }

  // ── Zod validation error ───────────────────────────────────────
  if (err instanceof ZodError) {
    const errors = err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }))
    return reply.code(422).send({
      success: false,
      message: 'Validation failed',
      code: 'VALIDATION_ERROR',
      errors,
    })
  }

  // ── JWT errors ────────────────────────────────────────────────
  if (err.name === 'JsonWebTokenError') {
    return reply.code(401).send({
      success: false,
      message: 'Invalid token',
      code: 'AUTH_TOKEN_INVALID',
    })
  }

  if (err.name === 'TokenExpiredError') {
    return reply.code(401).send({
      success: false,
      message: 'Token expired',
      code: 'AUTH_TOKEN_EXPIRED',
    })
  }

  // ── Fastify 404 ────────────────────────────────────────────────
  if (err.statusCode === 404) {
    return reply.code(404).send({
      success: false,
      message: 'Route not found',
      code: 'NOT_FOUND',
    })
  }

  // ── Payload too large ──────────────────────────────────────────
  if (err.statusCode === 413) {
    return reply.code(413).send({
      success: false,
      message: 'Request payload too large',
      code: 'PAYLOAD_TOO_LARGE',
    })
  }

  // ── Generic 500 ───────────────────────────────────────────────
  return reply.code(500).send({
    success: false,
    message: env.NODE_ENV === 'production'
      ? 'Something went wrong'
      : err.message,
    code: 'INTERNAL_ERROR',
    // Stack only in dev
    ...(env.NODE_ENV !== 'production' && { stack: err.stack }),
  })
}

/**
 * 404 handler — registered as fastify.setNotFoundHandler
 */
export const notFoundHandler = (req, reply) => {
  reply.code(404).send({
    success: false,
    message: `Route ${req.method} ${req.url} not found`,
    code: 'ROUTE_NOT_FOUND',
  })
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
const codeFromStatus = (status) => {
  const map = {
    400: 'BAD_REQUEST',
    401: 'UNAUTHORIZED',
    403: 'FORBIDDEN',
    404: 'NOT_FOUND',
    409: 'CONFLICT',
    422: 'VALIDATION_ERROR',
    429: 'RATE_LIMIT_EXCEEDED',
    500: 'INTERNAL_ERROR',
    501: 'NOT_IMPLEMENTED',
  }
  return map[status] || 'ERROR'
}

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1)