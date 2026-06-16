import { DayLog, HabitLog, Habit } from '../models/index.js'
import { getMonthRange, getTodayDate, getPreviousDate } from '../utils/dateHelper.js'
import { getCache, setCache, CACHE_KEYS, TTL } from '../config/redis.js'

export const calendarService = {
  // ── Get full month ───────────────────────────────────────────────
  getMonth: async (userId, month) => {
    const key = CACHE_KEYS.calendarMonth(userId, month)
    const cached = await getCache(key)
    if (cached) return cached

    const { from, to } = getMonthRange(month)

    const [dayLogs, habitLogs, habits] = await Promise.all([
      DayLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
      HabitLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
      Habit.find({ userId, isActive: true }).select('_id name category icon color').lean(),
    ])

    const dayLogMap = {}
    for (const log of dayLogs) dayLogMap[log.date] = log

    const habitLogMap = {}
    for (const log of habitLogs) {
      if (!habitLogMap[log.date]) habitLogMap[log.date] = []
      habitLogMap[log.date].push(log)
    }

    // Build day-by-day calendar
    const days = {}
    let d = new Date(from + 'T00:00:00')
    const end = new Date(to + 'T00:00:00')

    while (d <= end) {
      const dateStr = d.toISOString().split('T')[0]
      const dl = dayLogMap[dateStr]
      const hLogs = habitLogMap[dateStr] || []

      let status = 'none'
      if (dl) {
        if (dl.isFreezeDay) status = 'freeze'
        else if (dl.isCheatDay) status = 'cheat'
        else if (dl.isProductiveDay) status = 'completed'
        else if (dl.productivityScore > 0) status = 'partial'
        else if (dl.resolvedAt) status = 'missed'
        else if (dateStr === getTodayDate()) status = 'today'
      } else if (dateStr === getTodayDate()) {
        status = 'today'
      }

      days[dateStr] = {
        status,
        productivityScore: dl?.productivityScore || 0,
        completedHabits: dl?.completedHabits || 0,
        totalHabits: dl?.totalHabits || 0,
        mood: dl?.mood || null,
        habits: hLogs.map((hl) => {
          const habit = habits.find((h) => h._id.toString() === hl.habitId.toString())
          return {
            habitId: hl.habitId,
            name: habit?.name,
            icon: habit?.icon,
            isCompleted: hl.isCompleted,
            completionPercentage: hl.completionPercentage,
          }
        }),
      }

      d.setDate(d.getDate() + 1)
    }

    const result = { month, from, to, days }
    await setCache(key, result, TTL.LONG)
    return result
  },

  // ── Get single day breakdown ─────────────────────────────────────
  getDay: async (userId, date) => {
    const [dayLog, habitLogs, habits] = await Promise.all([
      DayLog.findOne({ userId, date }).lean(),
      HabitLog.find({ userId, date }).lean(),
      Habit.find({ userId, isActive: true }).lean(),
    ])

    return {
      date,
      dayLog: dayLog || null,
      habits: habitLogs.map((hl) => {
        const habit = habits.find((h) => h._id.toString() === hl.habitId.toString())
        return {
          ...hl,
          habitName: habit?.name,
          habitIcon: habit?.icon,
          habitColor: habit?.color,
          category: habit?.category,
        }
      }),
    }
  },

  // ── Streak chain map (for visual chain rendering) ────────────────
  getStreakMap: async (userId) => {
    // Returns last 90 days as a chain: consecutive productive days highlighted
    const today = getTodayDate()
    const from = new Date()
    from.setDate(from.getDate() - 89)
    const fromStr = from.toISOString().split('T')[0]

    const logs = await DayLog.find({
      userId,
      date: { $gte: fromStr, $lte: today },
    }).sort({ date: 1 }).lean()

    const map = {}
    for (const log of logs) {
      map[log.date] = {
        isProductiveDay: log.isProductiveDay,
        isFreezeDay: log.isFreezeDay,
        isCheatDay: log.isCheatDay,
        score: log.productivityScore,
      }
    }

    // Mark streak chain positions
    let chainLength = 0
    const dates = []
    let d = new Date(fromStr + 'T00:00:00')
    const endDate = new Date(today + 'T00:00:00')

    while (d <= endDate) {
      const dateStr = d.toISOString().split('T')[0]
      const entry = map[dateStr]
      const isGood = entry?.isProductiveDay || entry?.isFreezeDay || entry?.isCheatDay

      if (isGood) {
        chainLength += 1
      } else {
        chainLength = 0
      }

      dates.push({
        date: dateStr,
        isGoodDay: isGood || false,
        chainPosition: chainLength,
        ...entry,
      })

      d.setDate(d.getDate() + 1)
    }

    return { from: fromStr, to: today, chain: dates }
  },
}