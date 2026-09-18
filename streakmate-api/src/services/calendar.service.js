import { DayLog, HabitLog, Habit } from "../models/index.js";
import {
  getMonthRange,
  getTodayDate,
  getPreviousDate,
} from "../utils/dateHelper.js";
import { getCache, setCache, deleteCache, CACHE_KEYS, TTL } from "../config/redis.js";

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
      Habit.find({ userId, isActive: true })
        .select('_id name category icon color activeDays startDate')
        .lean(),
    ])

    const dayLogMap = {}
    for (const log of dayLogs) dayLogMap[log.date] = log

    const habitLogMap = {}
    for (const log of habitLogs) {
      if (!habitLogMap[log.date]) habitLogMap[log.date] = []
      habitLogMap[log.date].push(log)
    }

    const days = {}
    const todayStr = getTodayDate()

    // Walk dates as strings via noon-UTC parsing — avoids server-timezone
    // drift between this loop and getTodayDate()'s Asia/Kolkata calculation
    let d = new Date(from + 'T12:00:00Z')
    const end = new Date(to + 'T12:00:00Z')

    while (d <= end) {
      const dateStr = d.toISOString().split('T')[0]
      const dl = dayLogMap[dateStr]
      const hLogs = habitLogMap[dateStr] || []

      // dayOfWeek derived from the date string itself (noon UTC),
      // consistent regardless of server's local timezone
      const dayOfWeek = new Date(dateStr + 'T12:00:00Z').getUTCDay()

      // A habit only counts as "scheduled" on dateStr if:
      //  1. it runs on this day of week (activeDays includes dayOfWeek)
      //  2. the habit already existed by this date (startDate <= dateStr)
      const scheduledHabits = habits.filter((h) => {
        const runsThisDay = h.activeDays && h.activeDays.includes(dayOfWeek)
        const existedByThen = !h.startDate || h.startDate <= dateStr
        return runsThisDay && existedByThen
      }).length

      let status = 'none'
      if (dl) {
        if (dl.isFreezeDay) status = 'freeze'
        else if (dl.isCheatDay) status = 'cheat'
        else if (dl.isProductiveDay) status = 'completed'
        else if (dl.productivityScore > 0) status = 'partial'
        else if (dl.resolvedAt) status = 'missed'
        else if (dateStr === todayStr) status = 'today'
      } else if (dateStr === todayStr) {
        status = 'today'
      } else if (dateStr < todayStr) {
        // Past day, no DayLog — missed only if at least one habit
        // both ran on this weekday AND already existed by this date
        if (scheduledHabits > 0) status = 'missed'
      }

      days[dateStr] = {
        status,
        productivityScore: dl?.productivityScore || 0,
        completedHabits: dl?.completedHabits || 0,
        totalHabits: dl?.totalHabits || scheduledHabits,
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

      d.setUTCDate(d.getUTCDate() + 1)
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
    ]);

    // Derive isProductiveDay/score from HabitLog so the sheet doesn't
    // depend purely on a possibly-stale or never-created DayLog
    const totalHabits = habitLogs.length
    const completedHabits = habitLogs.filter((hl) => hl.isCompleted).length
    const productivityScore = totalHabits > 0
      ? Math.round((completedHabits / totalHabits) * 100)
      : (dayLog?.productivityScore || 0)
    const isProductiveDay = dayLog?.isProductiveDay
      ?? (totalHabits > 0 && completedHabits === totalHabits)

    return {
      date,
      dayLog: dayLog || {
        isProductiveDay,
        productivityScore,
        isFreezeDay: false,
        isCheatDay: false,
      },
      habits: habitLogs.map((hl) => {
        const habit = habits.find(
          (h) => h._id.toString() === hl.habitId.toString(),
        );
        return {
          ...hl,
          habitName: habit?.name,
          habitIcon: habit?.icon,
          habitColor: habit?.color,
          category: habit?.category,
        };
      }),
    };
  },

  // ── Streak chain map (for visual chain rendering) ────────────────
  getStreakMap: async (userId) => {
    // Returns last 90 days as a chain: consecutive productive days highlighted
    const today = getTodayDate();
    const from = new Date();
    from.setDate(from.getDate() - 89);
    const fromStr = from.toISOString().split("T")[0];

    const logs = await DayLog.find({
      userId,
      date: { $gte: fromStr, $lte: today },
    })
      .sort({ date: 1 })
      .lean();

    const map = {};
    for (const log of logs) {
      map[log.date] = {
        isProductiveDay: log.isProductiveDay,
        isFreezeDay: log.isFreezeDay,
        isCheatDay: log.isCheatDay,
        score: log.productivityScore,
      };
    }

    // Mark streak chain positions
    let chainLength = 0;
    const dates = [];
    let d = new Date(fromStr + "T00:00:00");
    const endDate = new Date(today + "T00:00:00");

    while (d <= endDate) {
      const dateStr = d.toISOString().split("T")[0];
      const entry = map[dateStr];
      const isGood =
        entry?.isProductiveDay || entry?.isFreezeDay || entry?.isCheatDay;

      if (isGood) {
        chainLength += 1;
      } else {
        chainLength = 0;
      }

      dates.push({
        date: dateStr,
        isGoodDay: isGood || false,
        chainPosition: chainLength,
        ...entry,
      });

      d.setDate(d.getDate() + 1);
    }

    return { from: fromStr, to: today, chain: dates };
  },
};