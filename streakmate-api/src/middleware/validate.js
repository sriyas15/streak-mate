import { z } from 'zod'

/**
 * validate
 * Fastify preHandler factory for Zod schema validation
 * Validates req.body, req.params, or req.query
 *
 * Usage:
 *   fastify.post('/register', {
 *     preHandler: [validate(registerSchema)],
 *     handler: authController.register
 *   })
 */
export const validate = (schema, target = 'body') => {
  return async (req, reply) => {
    try {
      const data = target === 'body'
        ? req.body
        : target === 'params'
        ? req.params
        : req.query

      const parsed = schema.parse(data)

      // Attach parsed (type-safe) data back
      if (target === 'body') req.body = parsed
      else if (target === 'params') req.params = parsed
      else req.query = parsed
    } catch (err) {
      if (err instanceof z.ZodError) {
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

      return reply.code(400).send({
        success: false,
        message: 'Invalid request data',
        code: 'BAD_REQUEST',
      })
    }
  }
}

/**
 * validateParams
 * Convenience wrapper for route params validation
 */
export const validateParams = (schema) => validate(schema, 'params')

/**
 * validateQuery
 * Convenience wrapper for query string validation
 */
export const validateQuery = (schema) => validate(schema, 'query')

// ─── Common reusable schemas ─────────────────────────────────────────────────
export const z_objectId = z
  .string()
  .regex(/^[a-f\d]{24}$/i, 'Invalid ID format')

export const z_date = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be in YYYY-MM-DD format')

export const z_paginationQuery = z.object({
  page: z.string().optional().default('1').transform(Number),
  limit: z.string().optional().default('20').transform(Number),
})

export const z_periodQuery = z.object({
  period: z.enum(['week', 'month', 'year']).optional().default('week'),
})