/**
 * responseHelper.js
 * Standardised API response shape used by all controllers
 *
 * All responses follow:
 * {
 *   success: boolean,
 *   message: string,
 *   data: object | null,
 *   meta: object | null,   ← pagination, counts etc
 *   serverTime: string
 * }
 */

export const sendSuccess = (reply, data = null, message = 'Success', statusCode = 200, meta = null) => {
  return reply.code(statusCode).send({
    success: true,
    message,
    data,
    ...(meta && { meta }),
    serverTime: new Date().toISOString(),
  })
}

export const sendCreated = (reply, data = null, message = 'Created successfully') => {
  return sendSuccess(reply, data, message, 201)
}

export const sendError = (reply, message = 'Something went wrong', statusCode = 500, code = 'ERROR') => {
  return reply.code(statusCode).send({
    success: false,
    message,
    code,
    serverTime: new Date().toISOString(),
  })
}

export const sendNotFound = (reply, entity = 'Resource') => {
  return sendError(reply, `${entity} not found`, 404, 'NOT_FOUND')
}

export const sendUnauthorized = (reply, message = 'Unauthorized') => {
  return sendError(reply, message, 401, 'UNAUTHORIZED')
}

export const sendForbidden = (reply, message = 'Forbidden') => {
  return sendError(reply, message, 403, 'FORBIDDEN')
}

export const sendValidationError = (reply, errors) => {
  return reply.code(422).send({
    success: false,
    message: 'Validation failed',
    code: 'VALIDATION_ERROR',
    errors,
    serverTime: new Date().toISOString(),
  })
}

// ─── Pagination meta builder ──────────────────────────────────────────────────
export const buildPaginationMeta = (total, page, limit) => ({
  total,
  page: Number(page),
  limit: Number(limit),
  totalPages: Math.ceil(total / limit),
  hasNextPage: Number(page) < Math.ceil(total / limit),
  hasPrevPage: Number(page) > 1,
})

// ─── Throw helpers (used in services) ────────────────────────────────────────
export const throwError = (message, statusCode = 500, code = null) => {
  const err = new Error(message)
  err.statusCode = statusCode
  if (code) err.code = code
  throw err
}

export const throwNotFound = (entity = 'Resource') =>
  throwError(`${entity} not found`, 404, 'NOT_FOUND')

export const throwBadRequest = (message) =>
  throwError(message, 400, 'BAD_REQUEST')

export const throwUnauthorized = (message = 'Unauthorized') =>
  throwError(message, 401, 'UNAUTHORIZED')

export const throwForbidden = (message = 'Forbidden') =>
  throwError(message, 403, 'FORBIDDEN')

export const throwConflict = (message) =>
  throwError(message, 409, 'CONFLICT')

export const throwNotImplemented = (message = 'Not yet implemented') =>
  throwError(message, 501, 'NOT_IMPLEMENTED')