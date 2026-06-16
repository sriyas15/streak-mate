/**
 * offlineSync middleware
 * Applied to the POST /sync endpoint
 *
 * Validates the sync payload shape before handing to syncService
 * Also handles the X-Last-Synced-At header from Flutter client
 */
export const offlineSync = async (req, reply) => {
  const { actions = [], lastSyncedAt } = req.body || {}

  // Validate action types
  const VALID_TYPES = [
    'HABIT_COMPLETE',
    'HABIT_UNCOMPLETE',
    'SUBTASK_UPDATE',
    'MOOD_UPDATE',
    'NOTE_UPDATE',
  ]

  const invalid = actions.filter((a) => !VALID_TYPES.includes(a.type))
  if (invalid.length > 0) {
    return reply.code(422).send({
      success: false,
      message: `Unknown action types: ${invalid.map((a) => a.type).join(', ')}`,
      code: 'INVALID_SYNC_ACTION',
    })
  }

  // Validate max batch size — prevent abuse
  if (actions.length > 200) {
    return reply.code(400).send({
      success: false,
      message: 'Sync batch too large — max 200 actions per request',
      code: 'SYNC_BATCH_TOO_LARGE',
    })
  }

  // Attach lastSyncedAt from header if not in body
  if (!req.body.lastSyncedAt) {
    req.body.lastSyncedAt = req.headers['x-last-synced-at'] || null
  }
}

/**
 * timestampInjector
 * Adds server timestamp to every response
 * Useful for Flutter client to track lastSyncedAt reliably
 */
export const timestampInjector = async (req, reply, payload) => {
  if (typeof payload === 'string') {
    try {
      const parsed = JSON.parse(payload)
      parsed.serverTime = new Date().toISOString()
      return JSON.stringify(parsed)
    } catch {
      return payload
    }
  }
  return payload
}