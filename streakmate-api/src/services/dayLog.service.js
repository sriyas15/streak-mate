import { DayLog, HabitLog, Habit, User } from '../models/index.js'
import { getTodayDate, getMonthRange, formatDate } from '../utils/dateHelper.js'
import { streakService } from './streak.service.js'
import { emitToUser, SOCKET_EVENTS } from '../socket/index.js'

export const dayLogService = {
  // ── Get today's daylog (upsert) ──────────────────────────────────
  getToday: async (userId) => {
    const today = getTodayDate()
    return DayLog.findOneAndUpdate(
      { userId, date: today },
      { $setOnInsert: { userId, date: today } },
      { upsert: true, new: true }
    )
  },

  // ── Get by date ──────────────────────────────────────────────────
  getByDate: async (userId, date) => {
    const log = await DayLog.findOne({ userId, date }).lean()
    if (!log) throwNotFound('Day log')
    return log
  },

  // ── Get range ────────────────────────────────────────────────────
  getRange: async (userId, { from, to }) => {
    return DayLog.find({
      userId,
      date: { $gte: from, $lte: to },
    }).sort({ date: 1 }).lean()
  },

  // ── Get calendar month ───────────────────────────────────────────
  getCalendar: async (userId, month) => {
    // month format: "2024-06"
    const { from, to } = getMonthRange(month)
    const logs = await DayLog.find({
      userId,
      date: { $gte: from, $lte: to },
    }).lean()

    // Map to date → status for easy calendar rendering
    const map = {}
    for (const log of logs) {
      let status = 'none'
      if (log.isFreezeDay) status = 'freeze'
      else if (log.isCheatDay) status = 'cheat'
      else if (log.isProductiveDay) status = 'completed'
      else if (log.productivityScore > 0) status = 'partial'
      else if (log.resolvedAt) status = 'missed'

      map[log.date] = {
        status,
        productivityScore: log.productivityScore,
        completedHabits: log.completedHabits,
        totalHabits: log.totalHabits,
        mood: log.mood,
      }
    }

    return { month, from, to, days: map }
  },

  // ── Update mood ──────────────────────────────────────────────────
  updateMood: async (userId, date, mood) => {
    const log = await DayLog.findOneAndUpdate(
      { userId, date },
      { mood },
      { new: true, upsert: true }
    )
    return log
  },

  // ── Update note ──────────────────────────────────────────────────
  updateNote: async (userId, date, note) => {
    const log = await DayLog.findOneAndUpdate(
      { userId, date },
      { note },
      { new: true, upsert: true }
    )
    return log
  },

  // ── Activate freeze ──────────────────────────────────────────────
  activateFreeze: async (userId, date, reason) => {
    const user = await User.findById(userId)
    if (!user) throwNotFound('User')

    if (user.freezesRemaining <= 0) {
      throwBadRequest('No freeze days remaining this month')
    }

    const today = getTodayDate()
    if (date > today) throwBadRequest('Cannot freeze a future date')

    const existing = await DayLog.findOne({ userId, date })
    if (existing?.isFreezeDay) throwBadRequest('This day is already frozen')
    if (existing?.isCheatDay) throwBadRequest('This day already has a cheat day applied')

    const [log] = await Promise.all([
      DayLog.findOneAndUpdate(
        { userId, date },
        { isFreezeDay: true, freezeReason: reason || null },
        { upsert: true, new: true }
      ),
      User.findByIdAndUpdate(userId, {
        $inc: { freezesUsed: 1, freezesRemaining: -1 },
      }),
    ])

    // Recalculate streak — freeze protects it
    await streakService.recalculate(userId)

    return { log, freezesRemaining: user.freezesRemaining - 1 }
  },

  // ── Activate cheat day ───────────────────────────────────────────
  activateCheatDay: async (userId, date) => {
    const user = await User.findById(userId)
    if (!user) throwNotFound('User')

    if (user.cheatDaysRemaining <= 0) {
      throwBadRequest('No cheat days remaining this month')
    }

    const existing = await DayLog.findOne({ userId, date })
    if (existing?.isCheatDay) throwBadRequest('Cheat day already applied')
    if (existing?.isFreezeDay) throwBadRequest('This day already has a freeze applied')

    const [log] = await Promise.all([
      DayLog.findOneAndUpdate(
        { userId, date },
        { isCheatDay: true },
        { upsert: true, new: true }
      ),
      User.findByIdAndUpdate(userId, {
        $inc: { cheatDaysUsed: 1, cheatDaysRemaining: -1 },
      }),
    ])

    await streakService.recalculate(userId)

    return { log, cheatDaysRemaining: user.cheatDaysRemaining - 1 }
  },

  // ── Undo freeze (same day only) ──────────────────────────────────
  undoFreeze: async (userId, date) => {
    const today = getTodayDate()
    if (date !== today) throwBadRequest('Can only undo a freeze on the same day it was applied')

    const log = await DayLog.findOne({ userId, date })
    if (!log?.isFreezeDay) throwBadRequest('No freeze to undo on this date')

    await Promise.all([
      DayLog.findOneAndUpdate({ userId, date }, { isFreezeDay: false, freezeReason: null }),
      User.findByIdAndUpdate(userId, { $inc: { freezesUsed: -1, freezesRemaining: 1 } }),
    ])

    await streakService.recalculate(userId)
  },

  // ── Recalculate productivity score for a date ─────────────────────
  // Called after every habit log update
  recalculate: async (userId, date) => {
    const dayOfWeek = new Date(date + 'T00:00:00').getDay()

    const habits = await Habit.find({
      userId,
      isActive: true,
      isArchived: false,
      activeDays: dayOfWeek,
      startDate: { $lte: date },
      $or: [{ endDate: null }, { endDate: { $gte: date } }],
    }).lean()

    if (habits.length === 0) return

    const habitIds = habits.map((h) => h._id)
    const logs = await HabitLog.find({ userId, date, habitId: { $in: habitIds } }).lean()

    const completedHabits = logs.filter((l) => l.isCompleted).length
    const totalHabits = habits.length
    const productivityScore = Math.round((completedHabits / totalHabits) * 100)
    const isProductiveDay = completedHabits === totalHabits

    const dayLog = await DayLog.findOneAndUpdate(
      { userId, date },
      {
        totalHabits,
        completedHabits,
        skippedHabits: totalHabits - completedHabits - logs.filter((l) => !l.isCompleted).length,
        productivityScore,
        isProductiveDay,
      },
      { upsert: true, new: true }
    )

    // After findOneAndUpdate in recalculate:
    emitToUser(userId, SOCKET_EVENTS.CALENDAR_UPDATED, {
      date,
      status: dayLog.isFreezeDay ? 'freeze' : dayLog.isCheatDay ? 'cheat' : isProductiveDay ? 'completed' : productivityScore > 0 ? 'partial' : 'missed',
      productivityScore,
      completedHabits,
      totalHabits,
    })

    // If it just became a productive day — update streak
    if (isProductiveDay) {
      await streakService.handleProductiveDay(userId, date)
      emitToUser(userId, SOCKET_EVENTS.STREAK_UPDATED, { date, productivityScore })
    }

    return dayLog
  },
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