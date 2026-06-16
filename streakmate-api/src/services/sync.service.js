import { HabitLog, DayLog, Habit, Streak } from '../models/index.js'
import { habitLogService } from './habitLog.service.js'
import { dayLogService } from './dayLog.service.js'
import { streakService } from './streak.service.js'
import { getTodayDate } from '../utils/dateHelper.js'

/**
 * Sync service — handles reconciliation of offline-queued actions
 * when the Flutter client comes back online.
 *
 * The client sends a sync payload:
 * {
 *   lastSyncedAt: "2024-06-04T10:00:00Z",
 *   actions: [
 *     { type: "HABIT_COMPLETE", habitId, date, subtaskResults, timestamp },
 *     { type: "SUBTASK_UPDATE", habitId, date, subtaskId, value, isCompleted, timestamp },
 *     { type: "MOOD_UPDATE", date, mood, timestamp },
 *     { type: "NOTE_UPDATE", date, note, timestamp },
 *   ]
 * }
 *
 * Server returns:
 * {
 *   syncedAt: "2024-06-04T12:00:00Z",
 *   serverUpdates: { habits, streaks, dayLogs, user }  ← anything changed server-side
 * }
 */

const ACTION_TYPES = {
  HABIT_COMPLETE: 'HABIT_COMPLETE',
  HABIT_UNCOMPLETE: 'HABIT_UNCOMPLETE',
  SUBTASK_UPDATE: 'SUBTASK_UPDATE',
  MOOD_UPDATE: 'MOOD_UPDATE',
  NOTE_UPDATE: 'NOTE_UPDATE',
}

export const syncService = {
  // ── Main sync handler ────────────────────────────────────────────
  sync: async (userId, { lastSyncedAt, actions = [] }) => {
    const errors = []
    const processedActions = []
    const today = getTodayDate()

    // Sort actions by timestamp — process in order
    const sorted = [...actions].sort(
      (a, b) => new Date(a.timestamp) - new Date(b.timestamp)
    )

    for (const action of sorted) {
      try {
        await processAction(userId, action, today)
        processedActions.push({ actionId: action.actionId, status: 'ok' })
      } catch (err) {
        errors.push({
          actionId: action.actionId,
          type: action.type,
          error: err.message,
        })
      }
    }

    // Pull server-side updates since lastSyncedAt
    const serverUpdates = await getServerUpdates(userId, lastSyncedAt)

    return {
      syncedAt: new Date().toISOString(),
      processedActions,
      errors,
      serverUpdates,
    }
  },

  // ── Pull-based sync — client sends lastSyncedAt, gets everything since ──
  pull: async (userId, lastSyncedAt) => {
    return getServerUpdates(userId, lastSyncedAt)
  },
}

// ─── Process a single offline action ─────────────────────────────────────────
const processAction = async (userId, action, today) => {
  // Only allow today's date for offline logs — security rule
  if (action.date && action.date !== today) {
    throw new Error(`Offline logs only accepted for today (${today})`)
  }

  switch (action.type) {
    case ACTION_TYPES.HABIT_COMPLETE: {
      // Upsert log + mark complete
      await habitLogService.createLog(userId, action.habitId, {
        date: action.date,
        loggedOffline: true,
        allowBackdate: false,
      })

      if (action.subtaskResults?.length > 0) {
        for (const result of action.subtaskResults) {
          await habitLogService.updateSubtaskResult(
            userId,
            action.habitId,
            action.date,
            result.subtaskId,
            { isCompleted: result.isCompleted, value: result.value }
          )
        }
      } else {
        await habitLogService.markComplete(userId, action.habitId, action.date)
      }
      break
    }

    case ACTION_TYPES.HABIT_UNCOMPLETE: {
      await habitLogService.markUncomplete(userId, action.habitId, action.date)
      break
    }

    case ACTION_TYPES.SUBTASK_UPDATE: {
      const log = await HabitLog.findOne({ userId, habitId: action.habitId, date: action.date })
      if (!log) {
        // Create the log first if it doesn't exist
        await habitLogService.createLog(userId, action.habitId, {
          date: action.date,
          loggedOffline: true,
        })
      }
      await habitLogService.updateSubtaskResult(
        userId,
        action.habitId,
        action.date,
        action.subtaskId,
        { isCompleted: action.isCompleted, value: action.value }
      )
      break
    }

    case ACTION_TYPES.MOOD_UPDATE: {
      await dayLogService.updateMood(userId, action.date, action.mood)
      break
    }

    case ACTION_TYPES.NOTE_UPDATE: {
      await dayLogService.updateNote(userId, action.date, action.note)
      break
    }

    default:
      throw new Error(`Unknown action type: ${action.type}`)
  }
}

// ─── Get all server-side changes since lastSyncedAt ──────────────────────────
const getServerUpdates = async (userId, lastSyncedAt) => {
  const since = lastSyncedAt ? new Date(lastSyncedAt) : new Date(0)

  const [habits, habitLogs, dayLogs, streaks] = await Promise.all([
    Habit.find({ userId, updatedAt: { $gt: since } }).lean(),
    HabitLog.find({ userId, updatedAt: { $gt: since } }).lean(),
    DayLog.find({ userId, updatedAt: { $gt: since } }).lean(),
    Streak.find({ userId, lastUpdated: { $gt: since } }).lean(),
  ])

  return { habits, habitLogs, dayLogs, streaks }
}