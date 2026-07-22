import { daysBetween, getPreviousDate } from './dateHelper.js'

/**
 * streakCalculator.js
 * Pure functions — no DB calls, no side effects
 * Used by streak.service.js and tests
 */

// ─── Check if two dates form a consecutive pair ───────────────────────────────
export const isConsecutive = (dateA, dateB) => {
  // Returns true if dateB is exactly 1 day after dateA
  const gap = daysBetween(dateA, dateB)
  return gap === 1
}

// ─── Calculate streak count from a sorted array of date strings ───────────────
export const calcStreakFromDates = (dates) => {
  if (!dates || dates.length === 0) return 0

  const sorted = [...dates].sort() // ascending
  let streak = 1

  for (let i = sorted.length - 1; i > 0; i--) {
    if (isConsecutive(sorted[i - 1], sorted[i])) {
      streak++
    } else {
      break
    }
  }

  return streak
}

/**
 * Calculate current and best streak from a sorted array of day log objects
 *
 * dayLogs: [{ date: "YYYY-MM-DD", isProductiveDay, isFreezeDay, isCheatDay }]
 * Returns: { currentStreak, bestStreak, currentStreakStart, bestStreakStart, bestStreakEnd }
 */
export const calcStreakFromLogs = (dayLogs, todayStr) => {
  if (!dayLogs || dayLogs.length === 0) {
    return {
      currentStreak: 0,
      bestStreak: 0,
      currentStreakStart: null,
      bestStreakStart: null,
      bestStreakEnd: null,
    }
  }

  const sorted = [...dayLogs].sort((a, b) => (a.date > b.date ? 1 : -1))

  let currentStreak = 0
  let currentStart = null
  let bestStreak = 0
  let bestStart = null
  let bestEnd = null
  let prevDate = null
  let runStart = null
  let runCount = 0

  for (const log of sorted) {
    const isGood = log.isProductiveDay || log.isFreezeDay || log.isCheatDay

    if (!isGood) {
      if (todayStr && log.date === todayStr) {
        continue
      }
      // Streak broken — reset run
      if (runCount > bestStreak) {
        bestStreak = runCount
        bestStart = runStart
        bestEnd = prevDate
      }
      runCount = 0
      runStart = null
      prevDate = null
      continue
    }

    if (!prevDate) {
      // Start fresh run
      runStart = log.date
      runCount = 1
    } else {
      const gap = daysBetween(prevDate, log.date)
      if (gap === 1) {
        runCount++
      } else {
        // Gap > 1 — broken
        if (runCount > bestStreak) {
          bestStreak = runCount
          bestStart = runStart
          bestEnd = prevDate
        }
        runStart = log.date
        runCount = 1
      }
    }

    prevDate = log.date
  }

  // Final run
  if (runCount > bestStreak) {
    bestStreak = runCount
    bestStart = runStart
    bestEnd = prevDate
  }

  currentStreak = runCount
  currentStart = runStart

  return {
    currentStreak,
    bestStreak,
    currentStreakStart: currentStart,
    bestStreakStart: bestStart,
    bestStreakEnd: bestEnd,
  }
}

/**
 * Determine if adding a new good day extends or starts a streak
 *
 * lastGoodDate: the last date that was productive/freeze/cheat
 * newDate: the date being processed now
 * Returns: "extend" | "start" | "same"
 */
export const getStreakAction = (lastGoodDate, newDate) => {
  if (!lastGoodDate) return 'start'
  if (lastGoodDate === newDate) return 'same'

  const gap = daysBetween(lastGoodDate, newDate)
  if (gap === 1) return 'extend'
  if (gap === 0) return 'same'
  return 'start' // gap > 1 — broken
}

/**
 * Get upcoming milestone days
 * currentStreak: current day count
 * Returns array of upcoming milestone targets
 */
export const getUpcomingMilestones = (currentStreak) => {
  const MILESTONES = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365]
  return MILESTONES
    .filter((m) => m > currentStreak)
    .slice(0, 3) // next 3 milestones
    .map((m) => ({
      days: m,
      daysAway: m - currentStreak,
      label: getMilestoneLabel(m),
    }))
}

/**
 * Check if a date is protected (freeze or cheat day)
 * Prevents streak breaks even if no habits were completed
 */
export const isProtectedDay = (dayLog) => {
  if (!dayLog) return false
  return dayLog.isFreezeDay || dayLog.isCheatDay
}

// ─── Milestone labels ────────────────────────────────────────────────────────
export const getMilestoneLabel = (days) => {
  const labels = {
    3:   'Getting Started 🌱',
    7:   'One Week Strong 🔥',
    14:  'Two Week Warrior ⚡',
    21:  'Habit Forming 🧠',
    30:  '30 Day Legend 🏆',
    50:  'Fifty and Fierce 💪',
    75:  'Unstoppable 🚀',
    100: '100 Day Champion 👑',
    150: 'Elite Performer 🌟',
    200: 'Almost 365 👀',
    365: 'One Full Year 🎯',
  }
  return labels[days] || `${days} Day Streak`
}