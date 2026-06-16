/**
 * timezoneMiddleware
 * Applied globally after authenticate
 *
 * Why this exists:
 * - Streaks depend on "today" — which differs per timezone
 * - A user in Dubai doing a habit at 11:30 PM must count for THEIR day
 * - We store dates as "YYYY-MM-DD" strings — they must be in user's TZ
 *
 * Attaches req.userDate (today in user's timezone) to every request
 * Controllers and services use req.userDate instead of new Date()
 */
export const timezoneMiddleware = async (req, reply) => {
  if (!req.user) return

  const timezone = req.user.timezone || 'Asia/Kolkata'

  try {
    const now = new Date()
    const userDateStr = now.toLocaleDateString('en-CA', { timeZone: timezone })
    // en-CA gives YYYY-MM-DD format natively

    req.userDate = userDateStr
    req.userTimezone = timezone
  } catch {
    // Fallback to UTC if invalid timezone
    req.userDate = new Date().toISOString().split('T')[0]
    req.userTimezone = 'UTC'
  }
}