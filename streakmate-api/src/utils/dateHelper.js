/**
 * dateHelper.js
 * All date operations in one place — timezone-safe
 *
 * Rule: dates are stored as "YYYY-MM-DD" strings throughout the app
 * Never store raw JS Date objects for habit/streak/log dates
 */

// ─── Get today's date in a specific timezone ─────────────────────────────────
export const getTodayDate = (timezone = 'Asia/Kolkata') => {
  return new Date().toLocaleDateString('en-CA', { timeZone: timezone })
  // en-CA gives YYYY-MM-DD natively
}

// ─── Get today's date in UTC ──────────────────────────────────────────────────
export const getTodayUTC = () => {
  return new Date().toISOString().split('T')[0]
}

// ─── Get yesterday's date string ────────────────────────────────────────────
export const getYesterdayDate = (timezone = 'Asia/Kolkata') => {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return d.toLocaleDateString('en-CA', { timeZone: timezone })
}

// ─── Get N days ago ──────────────────────────────────────────────────────────
export const getDaysAgo = (n, timezone = 'Asia/Kolkata') => {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return d.toLocaleDateString('en-CA', { timeZone: timezone })
}

// ─── Get the previous calendar date ─────────────────────────────────────────
export const getPreviousDate = (dateStr) => {
  const d = new Date(dateStr + 'T12:00:00Z') // noon UTC avoids DST edge cases
  d.setDate(d.getDate() - 1)
  return d.toISOString().split('T')[0]
}

// ─── Get the next calendar date ──────────────────────────────────────────────
export const getNextDate = (dateStr) => {
  const d = new Date(dateStr + 'T12:00:00Z')
  d.setDate(d.getDate() + 1)
  return d.toISOString().split('T')[0]
}

// ─── Format a Date object to YYYY-MM-DD ──────────────────────────────────────
export const formatDate = (date) => {
  if (typeof date === 'string') return date
  return date.toISOString().split('T')[0]
}

// ─── Parse a YYYY-MM-DD string into a JS Date (noon UTC) ─────────────────────
export const parseDate = (dateStr) => {
  return new Date(dateStr + 'T12:00:00Z')
}

// ─── Days between two YYYY-MM-DD strings ────────────────────────────────────
export const daysBetween = (dateA, dateB) => {
  const a = parseDate(dateA)
  const b = parseDate(dateB)
  const diff = Math.abs(b - a)
  return Math.round(diff / (1000 * 60 * 60 * 24))
}

// ─── Is date A before date B ──────────────────────────────────────────────────
export const isBefore = (dateA, dateB) => {
  return parseDate(dateA) < parseDate(dateB)
}

// ─── Is dateStr today (in given timezone) ────────────────────────────────────
export const isToday = (dateStr, timezone = 'Asia/Kolkata') => {
  return dateStr === getTodayDate(timezone)
}

// ─── Current week range (Mon → Sun) ─────────────────────────────────────────
export const getWeekRange = (date = new Date()) => {
  const d = new Date(date)
  const day = d.getDay() // 0=Sun ... 6=Sat
  const diffToMon = day === 0 ? -6 : 1 - day

  const mon = new Date(d)
  mon.setDate(d.getDate() + diffToMon)

  const sun = new Date(mon)
  sun.setDate(mon.getDate() + 6)

  return {
    from: mon.toISOString().split('T')[0],
    to: sun.toISOString().split('T')[0],
  }
}

// ─── Month range ─────────────────────────────────────────────────────────────
// month param: "2024-06" or omit for current month
export const getMonthRange = (month) => {
  let year, m

  if (month) {
    [year, m] = month.split('-').map(Number)
  } else {
    const now = new Date()
    year = now.getFullYear()
    m = now.getMonth() + 1
  }

  const from = `${year}-${String(m).padStart(2, '0')}-01`
  const lastDay = new Date(year, m, 0).getDate()
  const to = `${year}-${String(m).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`

  return { from, to }
}

// ─── Year range ───────────────────────────────────────────────────────────────
export const getYearRange = (year) => {
  const y = year || new Date().getFullYear()
  return {
    from: `${y}-01-01`,
    to: `${y}-12-31`,
  }
}

// ─── Get all dates between two YYYY-MM-DD strings (inclusive) ────────────────
export const getDateRange = (from, to) => {
  const dates = []
  let d = parseDate(from)
  const end = parseDate(to)

  while (d <= end) {
    dates.push(d.toISOString().split('T')[0])
    d.setDate(d.getDate() + 1)
  }

  return dates
}

// ─── Get day of week name ────────────────────────────────────────────────────
export const getDayName = (dateStr) => {
  const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  return DAYS[parseDate(dateStr).getDay()]
}

// ─── Get short month name ─────────────────────────────────────────────────────
export const getMonthName = (month) => {
  const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  const [, m] = month.split('-').map(Number)
  return MONTHS[m - 1]
}

// ─── Validate YYYY-MM-DD format ───────────────────────────────────────────────
export const isValidDate = (dateStr) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false
  const d = new Date(dateStr + 'T12:00:00Z')
  return !isNaN(d.getTime())
}

// ─── Current month string ─────────────────────────────────────────────────────
export const getCurrentMonth = () => {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}