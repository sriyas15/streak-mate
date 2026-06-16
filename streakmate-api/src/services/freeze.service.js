import { User, DayLog } from '../models/index.js'
import { streakService } from './streak.service.js'
import { getTodayDate } from '../utils/dateHelper.js'

export const freezeService = {
  // ── Get freeze/cheat balance ─────────────────────────────────────
  getBalance: async (userId) => {
    const user = await User.findById(userId)
      .select('freezesRemaining freezesUsed totalFreezesAlloted cheatDaysRemaining cheatDaysUsed cheatDaysAlloted freezeResetDate')
      .lean()
    if (!user) throwNotFound('User')
    return user
  },

  // ── Activate freeze ──────────────────────────────────────────────
  activateFreeze: async (userId, { date, reason }) => {
    const user = await User.findById(userId)
    if (!user) throwNotFound('User')
    if (user.freezesRemaining <= 0) throwBadRequest('No freeze days remaining this month')

    const today = getTodayDate()
    if (date > today) throwBadRequest('Cannot freeze a future date')

    const existingLog = await DayLog.findOne({ userId, date })
    if (existingLog?.isFreezeDay) throwBadRequest('This day is already frozen')
    if (existingLog?.isCheatDay) throwBadRequest('Cannot freeze a day with cheat day active')
    if (existingLog?.isProductiveDay) throwBadRequest('This was already a productive day — no freeze needed')

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

    await streakService.recalculate(userId)

    return {
      log,
      balance: {
        freezesRemaining: user.freezesRemaining - 1,
        cheatDaysRemaining: user.cheatDaysRemaining,
      },
    }
  },

  // ── Activate cheat day ───────────────────────────────────────────
  activateCheatDay: async (userId, date) => {
    const user = await User.findById(userId)
    if (!user) throwNotFound('User')
    if (user.cheatDaysRemaining <= 0) throwBadRequest('No cheat days remaining this month')

    const today = getTodayDate()
    if (date > today) throwBadRequest('Cannot apply cheat day to a future date')

    const existingLog = await DayLog.findOne({ userId, date })
    if (existingLog?.isCheatDay) throwBadRequest('Cheat day already applied to this date')
    if (existingLog?.isFreezeDay) throwBadRequest('Cannot apply cheat day — this date has a freeze')

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

    return {
      log,
      balance: {
        freezesRemaining: user.freezesRemaining,
        cheatDaysRemaining: user.cheatDaysRemaining - 1,
      },
    }
  },

  // ── Get freeze/cheat history ─────────────────────────────────────
  getHistory: async (userId) => {
    const logs = await DayLog.find({
      userId,
      $or: [{ isFreezeDay: true }, { isCheatDay: true }],
    })
      .sort({ date: -1 })
      .select('date isFreezeDay isCheatDay freezeReason createdAt')
      .lean()

    return logs.map((log) => ({
      date: log.date,
      type: log.isFreezeDay ? 'freeze' : 'cheat',
      reason: log.freezeReason || null,
      usedAt: log.createdAt,
    }))
  },

  // ── Monthly freeze reset (called by scheduler on 1st of month) ───
  resetMonthlyAllowances: async () => {
    const today = getTodayDate()
    await User.updateMany(
      { isActive: true, isDeleted: false },
      {
        $set: {
          freezesUsed: 0,
          freezesRemaining: 3,       // from AppConfig ideally
          cheatDaysUsed: 0,
          cheatDaysRemaining: 2,
          freezeResetDate: today,
        },
      }
    )
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