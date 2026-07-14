import { DayLog, HabitLog, Habit, Streak, User } from '../models/index.js'
import { getCache, setCache, CACHE_KEYS, TTL } from '../config/redis.js'
import { getWeekRange, getMonthRange, getYearRange, getTodayDate } from '../utils/dateHelper.js'

export const analyticsService = {
  // ── Overview ────────────────────────────────────────────────────
  getOverview: async (userId, period) => {
    const cached = await getCache(CACHE_KEYS.analytics(userId, period))
    if (cached) return cached

    const { from, to } = getRangeByPeriod(period)
    const [dayLogs, user, habitLogs] = await Promise.all([
      DayLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
      User.findById(userId).select('currentStreakDays bestStreakDays level xpPoints').lean(),
      HabitLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
    ])

    const totalDays = dayLogs.length
    const productiveDays = dayLogs.filter((d) => d.isProductiveDay).length
    const missedDays = dayLogs.filter(
      (d) => d.resolvedAt && !d.isProductiveDay && !d.isFreezeDay && !d.isCheatDay
    ).length
    const avgScore =
      totalDays > 0
        ? Math.round(dayLogs.reduce((a, d) => a + (d.productivityScore || 0), 0) / totalDays)
        : 0

    const overview = {
      period,
      from,
      to,
      totalDays,
      productiveDays,
      missedDays,
      avgProductivityScore: avgScore,
      successRate: totalDays > 0 ? Math.round((productiveDays / totalDays) * 100) : 0,
      currentStreak: user.currentStreakDays,
      bestStreak: user.bestStreakDays,
      level: user.level,
      xpPoints: user.xpPoints,
      totalHabitsCompleted: habitLogs.filter((l) => l.isCompleted).length,
      totalHabitsScheduled: habitLogs.length,
    }

    await setCache(CACHE_KEYS.analytics(userId, period), overview, TTL.LONG)
    return overview
  },

  // ── Productive days ──────────────────────────────────────────────
  getProductiveDays: async (userId, month) => {
    const { from, to } = getMonthRange(month)
    const logs = await DayLog.find({
      userId,
      date: { $gte: from, $lte: to },
    }).lean()

    const productive = logs.filter((d) => d.isProductiveDay).length
    const total = logs.filter((d) => d.resolvedAt).length

    return {
      month,
      productiveDays: productive,
      totalResolved: total,
      missedDays: total - productive,
      rate: total > 0 ? Math.round((productive / total) * 100) : 0,
      days: logs.map((d) => ({
        date: d.date,
        status: d.isProductiveDay ? 'productive'
          : d.isFreezeDay ? 'freeze'
          : d.isCheatDay ? 'cheat'
          : d.resolvedAt ? 'missed'
          : 'pending',
        score: d.productivityScore,
      })),
    }
  },

  // ── Category performance ─────────────────────────────────────────
  getCategoryPerformance: async (userId, period) => {
    const { from, to } = getRangeByPeriod(period)

    const habits = await Habit.find({ userId, isActive: true }).lean()
    const habitIds = habits.map((h) => h._id)

    const logs = await HabitLog.find({
      userId,
      habitId: { $in: habitIds },
      date: { $gte: from, $lte: to },
    }).lean()

    const categoryMap = {}
    for (const habit of habits) {
      if (!categoryMap[habit.category]) {
        categoryMap[habit.category] = { total: 0, completed: 0 }
      }
    }

    for (const log of logs) {
      const habit = habits.find((h) => h._id.toString() === log.habitId.toString())
      if (!habit) continue
      categoryMap[habit.category].total += 1
      if (log.isCompleted) categoryMap[habit.category].completed += 1
    }

    return Object.entries(categoryMap).map(([category, data]) => ({
      category,
      completionRate: data.total > 0 ? Math.round((data.completed / data.total) * 100) : 0,
      completed: data.completed,
      total: data.total,
    }))
  },

  // ── Weekly summary ───────────────────────────────────────────────
  getWeeklySummary: async (userId) => {
    const { from, to } = getWeekRange()
    const logs = await DayLog.find({ userId, date: { $gte: from, $lte: to } }).lean()

    return {
      from,
      to,
      days: logs.map((d) => ({
        date: d.date,
        score: d.productivityScore,
        isProductiveDay: d.isProductiveDay,
      })),
      avgScore:
        logs.length > 0
          ? Math.round(logs.reduce((a, d) => a + (d.productivityScore || 0), 0) / logs.length)
          : 0,
      productiveDays: logs.filter((d) => d.isProductiveDay).length,
    }
  },

  // ── Monthly report ───────────────────────────────────────────────
  getMonthlyReport: async (userId, month) => {
    const { from, to } = getMonthRange(month)
    const [dayLogs, habitLogs, habits] = await Promise.all([
      DayLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
      HabitLog.find({ userId, date: { $gte: from, $lte: to } }).lean(),
      Habit.find({ userId, isActive: true }).lean(),
    ])

    const productive = dayLogs.filter((d) => d.isProductiveDay).length
    const total = dayLogs.filter((d) => d.resolvedAt).length

    const habitStats = habits.map((habit) => {
      const logs = habitLogs.filter((l) => l.habitId.toString() === habit._id.toString())
      const completed = logs.filter((l) => l.isCompleted).length
      return {
        habitId: habit._id,
        name: habit.name,
        category: habit.category,
        completionRate: logs.length > 0 ? Math.round((completed / logs.length) * 100) : 0,
        completed,
        total: logs.length,
      }
    })

    return {
      month,
      productiveDays: productive,
      totalDays: total,
      successRate: total > 0 ? Math.round((productive / total) * 100) : 0,
      habitStats,
    }
  },

  // ── Insights (string-based summaries) ───────────────────────────
  getInsights: async (userId) => {
    const { from, to } = getWeekRange()
    const logs = await HabitLog.find({
      userId,
      date: { $gte: from, $lte: to },
    }).lean()

    const insights = []

    // Best day of the week
    const byDay = {}
    for (const log of logs) {
      const day = new Date(log.date + 'T00:00:00').getDay()
      if (!byDay[day]) byDay[day] = { completed: 0, total: 0 }
      byDay[day].total += 1
      if (log.isCompleted) byDay[day].completed += 1
    }

    const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    const bestDay = Object.entries(byDay).sort(
      ([, a], [, b]) => b.completed / b.total - a.completed / a.total
    )[0]
    if (bestDay) insights.push(`You're most consistent on ${DAYS[bestDay[0]]}s 📅`)

    // Weakest habit
    const habits = await Habit.find({ userId, isActive: true }).lean()
    const habitRates = habits.map((h) => {
      const hLogs = logs.filter((l) => l.habitId.toString() === h._id.toString())
      const rate = hLogs.length > 0 ? hLogs.filter((l) => l.isCompleted).length / hLogs.length : 0
      return { name: h.name, rate }
    })
    const weakest = habitRates.sort((a, b) => a.rate - b.rate)[0]
    if (weakest && weakest.rate < 0.5) {
      insights.push(`${weakest.name} needs more attention this week 💪`)
    }

    // Streak insight
    const user = await User.findById(userId).select('currentStreakDays').lean()
    if (user.currentStreakDays >= 7) {
      insights.push(`${user.currentStreakDays} day streak! You're unstoppable 🔥`)
    }

    return insights
  },

  // ── Heatmap data (GitHub-style) ──────────────────────────────────
  getHeatmap: async (userId, year) => {
    const from = `${year}-01-01`
    const to = `${year}-12-31`

    const logs = await DayLog.find({
      userId,
      date: { $gte: from, $lte: to },
    }).select('date productivityScore isProductiveDay').lean()

    const map = {}
    for (const log of logs) {
      map[log.date] = {
        score: log.productivityScore,
        isProductiveDay: log.isProductiveDay,
      }
    }

    return { year, heatmap: map }
  },

  // ── Per habit analytics ──────────────────────────────────────────
  getHabitAnalytics: async (userId, habitId, period) => {
    const { from, to } = getRangeByPeriod(period)
    const logs = await HabitLog.find({
      userId,
      habitId,
      date: { $gte: from, $lte: to },
    }).lean()

    const completed = logs.filter((l) => l.isCompleted).length
    const streak = await Streak.findOne({ userId, habitId }).lean()

    return {
      habitId,
      period,
      from,
      to,
      totalLogs: logs.length,
      completedLogs: completed,
      completionRate: logs.length > 0 ? Math.round((completed / logs.length) * 100) : 0,
      currentStreak: streak?.currentStreakCount || 0,
      bestStreak: streak?.bestStreakCount || 0,
      avgCompletionPercentage:
        logs.length > 0
          ? Math.round(logs.reduce((a, l) => a + l.completionPercentage, 0) / logs.length)
          : 0,
    }
  },
}

// ─── Helper ──────────────────────────────────────────────────────────────────
const getRangeByPeriod = (period) => {
  if (period === 'week') return getWeekRange()
  if (period === 'month') return getMonthRange()
  if (period === 'year') return getYearRange()
  return getWeekRange()
}