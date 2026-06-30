import { HabitLog, Habit, Subtask, DayLog } from '../models/index.js'
import { getTodayDate } from '../utils/dateHelper.js'
import { streakService } from './streak.service.js'
import { dayLogService } from './dayLog.service.js'
import { enqueueAchievementCheck } from '../config/bullmq.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'
import { gamificationService } from './gamification.service.js'

export const habitLogService = {
  // ── Create log (upsert — safe to call multiple times) ────────────
  createLog: async (userId, habitId, body) => {
    const habit = await Habit.findOne({ _id: habitId, userId })
    if (!habit) throwNotFound('Habit')

    const date = body.date || getTodayDate()

    // Reject backdated logs (only today allowed offline)
    if (date !== getTodayDate() && !body.allowBackdate) {
      throwBadRequest('Backdated logs are not allowed')
    }

    const subtasks = await Subtask.find({ habitId, isActive: true }).lean()

    const subtaskResults = subtasks.map((s) => ({
      subtaskId: s._id,
      isCompleted: false,
      value: null,
      completedAt: null,
    }))

    const log = await HabitLog.findOneAndUpdate(
      { userId, habitId, date },
      {
        $setOnInsert: {
          userId,
          habitId,
          date,
          subtaskResults,
          loggedOffline: body.loggedOffline || false,
        },
      },
      { upsert: true, new: true }
    )

    return log
  },

  // ── Get all logs (paginated) ─────────────────────────────────────
  getLogs: async (userId, habitId, { page, limit }) => {
    const skip = (page - 1) * limit
    const [logs, total] = await Promise.all([
      HabitLog.find({ userId, habitId }).sort({ date: -1 }).skip(skip).limit(Number(limit)).lean(),
      HabitLog.countDocuments({ userId, habitId }),
    ])
    return { logs, total, page: Number(page), limit: Number(limit) }
  },

  // ── Get logs in range ────────────────────────────────────────────
  getLogsInRange: async (userId, habitId, { from, to }) => {
    return HabitLog.find({
      userId,
      habitId,
      date: { $gte: from, $lte: to },
    }).sort({ date: 1 }).lean()
  },

  // ── Get log by date ──────────────────────────────────────────────
  getLogByDate: async (userId, habitId, date) => {
    const log = await HabitLog.findOne({ userId, habitId, date }).lean()
    if (!log) throwNotFound('Log')
    return log
  },

  // ── Update log ───────────────────────────────────────────────────
  updateLog: async (userId, habitId, date, updates) => {
    const log = await HabitLog.findOneAndUpdate(
      { userId, habitId, date },
      updates,
      { new: true }
    )
    if (!log) throwNotFound('Log')
    return log
  },

  // ── Update single subtask result ─────────────────────────────────
  updateSubtaskResult: async (userId, habitId, date, subtaskId, { isCompleted, value }) => {
    const log = await HabitLog.findOne({ userId, habitId, date })
    if (!log) throwNotFound('Log')

    const result = log.subtaskResults.find((r) => r.subtaskId.toString() === subtaskId)
    if (!result) throwNotFound('Subtask result')
    
    const wasCompleted = result.isCompleted

    result.isCompleted = isCompleted
    result.value = value ?? result.value
    result.completedAt = isCompleted ? new Date() : null

    // Recalculate completion percentage
    const habit = await Habit.findById(habitId)
    const subtasks = await Subtask.find({ habitId, isActive: true }).lean()
    const { percentage, isComplete } = calcCompletion(habit, subtasks, log.subtaskResults)

    log.completionPercentage = percentage
    log.isCompleted = isComplete
    if (isComplete && !log.completedAt) log.completedAt = new Date()
    if (!isComplete) log.completedAt = null

    await log.save()

    if (isCompleted && !wasCompleted) {
      await gamificationService.awardXP(userId, 10, `subtask_complete:${subtaskId}`)
    }

    if (isCompleted && !wasCompleted) {
  console.log(`💰 Awarding XP to ${userId} for subtask ${subtaskId}`)
  await gamificationService.awardXP(userId, 10, `subtask_complete:${subtaskId}`)
}

    // If just completed — trigger streak update + achievement check
    if (isComplete) {
      await streakService.handleHabitComplete(userId, habitId, date)
      await dayLogService.recalculate(userId, date)
      await enqueueAchievementCheck(userId, 'habit_complete')
      emitToUser(userId, SOCKET_EVENTS.HABIT_COMPLETED, { habitId, date })
    }

    return log
  },

  // ── Mark habit complete ──────────────────────────────────────────
  markComplete: async (userId, habitId, date) => {
    const log = await HabitLog.findOne({ userId, habitId, date })
    if (!log) throwNotFound('Log')

    // Mark all required subtasks as complete
    const subtasks = await Subtask.find({ habitId, isActive: true }).lean()
    for (const subtask of subtasks) {
      const result = log.subtaskResults.find((r) => r.subtaskId.toString() === subtask._id.toString())
      if (result && subtask.isRequired) {
        result.isCompleted = true
        result.completedAt = new Date()
      }
    }

    log.isCompleted = true
    log.completionPercentage = 100
    log.completedAt = new Date()
    await log.save()

    // After await log.save(), before streakService call:
    const newlyCompleted = subtasks.filter((s) => {
      const result = log.subtaskResults.find((r) => r.subtaskId.toString() === s._id.toString())
      return result?.isCompleted  // all required ones were just set to true
    })
    if (newlyCompleted.length > 0) {
      await gamificationService.awardXP(userId, newlyCompleted.length * 10, `mark_complete:${habitId}`)
    }

    await streakService.handleHabitComplete(userId, habitId, date)
    await dayLogService.recalculate(userId, date)
    await enqueueAchievementCheck(userId, 'habit_complete')
    emitToUser(userId, SOCKET_EVENTS.HABIT_COMPLETED, { habitId, date })

    return log
  },

  // ── Mark habit uncomplete ────────────────────────────────────────
  markUncomplete: async (userId, habitId, date) => {
    const log = await HabitLog.findOneAndUpdate(
      { userId, habitId, date },
      { isCompleted: false, completionPercentage: 0, completedAt: null },
      { new: true }
    )
    if (!log) throwNotFound('Log')

    await streakService.handleHabitUncomplete(userId, habitId, date)
    await dayLogService.recalculate(userId, date)

    return log
  },
}

// ─── Calculate completion based on habit rule ────────────────────────────────
const calcCompletion = (habit, subtasks, results) => {
  const required = subtasks.filter((s) => s.isRequired)
  const completedRequired = required.filter((s) => {
    const r = results.find((r) => r.subtaskId.toString() === s._id.toString())
    return r?.isCompleted
  })

  const total = subtasks.length
  const completed = results.filter((r) => r.isCompleted).length
  const percentage = total > 0 ? Math.round((completed / total) * 100) : 0

  let isComplete = false
  if (habit.completionRule === 'all_required') {
    isComplete = required.length > 0
      ? completedRequired.length === required.length
      : completed === total
  } else if (habit.completionRule === 'percentage') {
    isComplete = percentage >= habit.completionThreshold
  } else {
    isComplete = percentage === 100
  }

  return { percentage, isComplete }
}

const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}

const throwBadRequest = (message) => {
  const err = new Error(message)
  err.statusCode = 400
  throw err
}