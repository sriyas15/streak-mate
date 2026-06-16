import { NotificationTemplate } from '../models/index.js'

/**
 * notifCopyPicker.js
 * Picks the right notification copy at send time
 *
 * Priority:
 * 1. DB template (NotificationTemplate collection) — editable without deploy
 * 2. Hardcoded fallback below — ensures app works before templates are seeded
 */

// ─── Hardcoded fallbacks ──────────────────────────────────────────────────────
const FALLBACK_TEMPLATES = {
  daily_reminder: {
    title: "⏰ Time to check your habits",
    variants: [
      "Your habits won't track themselves. Let's go 💪",
      "Quick check-in time! How's your day going? 📋",
      "Reminder: your streak is counting on you 🔥",
    ],
  },
  habit_reminder: {
    title: "🔔 {{habitName}} reminder",
    variants: [
      "Don't forget: {{habitName}} is on your list today",
      "{{habitName}} — still waiting for you 👀",
      "Time for {{habitName}}! Keep the streak alive 🔥",
    ],
  },
  streak_warning: {
    title: "⚠️ Streak at risk",
    variants: [
      "You have {{remaining}} habits left. Your {{streakCount}} day streak needs you!",
      "1 hour left to save your {{streakCount}} day streak ⏰",
      "Almost midnight. Almost a broken streak. Don't 🙏",
    ],
  },
  streak_at_risk: {
    title: "🔥 {{streakCount}} days on the line",
    variants: [
      "{{streakCount}} days. Don't let it end tonight.",
      "Your streak called. It's scared. Go do your habits 😤",
      "{{remaining}} habits left. You've survived harder things.",
    ],
  },
  streak_broken: {
    title: "💔 Streak ended at {{streakCount}} days",
    variants: [
      "Your {{streakCount}} day streak ended. But today is day 1 of the next one 💪",
      "Streaks end. Legends restart. Today's a new beginning 🔥",
      "{{streakCount}} days was amazing. Time to beat it 🏆",
    ],
  },
  streak_milestone: {
    title: "🔥 {{streakCount}} day streak!",
    variants: [
      "{{streakCount}} days straight! You're in rare territory now 👑",
      "{{streakCount}} day streak unlocked. Who ARE you? 🐐",
      "{{streakCount}} consecutive days of showing up. Respect. 🏆",
    ],
  },
  streak_restored: {
    title: "❄️ Streak saved!",
    variants: [
      "Freeze used. Streak protected. Back at it tomorrow 💪",
      "Crisis averted. Streak intact. Sleep well ❄️",
    ],
  },
  freeze_used: {
    title: "❄️ Freeze activated",
    variants: [
      "Freeze day used. Streak is safe for today ❄️",
      "Streak protected. You have {{freezesRemaining}} freezes left this month.",
    ],
  },
  cheat_day_used: {
    title: "😏 Cheat day used",
    variants: [
      "Cheat day activated. Streak protected. Don't make it a habit 😏",
      "One cheat day won't kill the streak. Back on track tomorrow 💪",
    ],
  },
  freeze_running_low: {
    title: "⚠️ Only {{freezesRemaining}} freeze left",
    variants: [
      "You're down to {{freezesRemaining}} freeze day this month. Use it wisely ❄️",
      "Last freeze standing. Make it count 🧊",
    ],
  },
  funny_morning: {
    title: "☀️ Good morning, champ",
    variants: [
      "New day. New chance. Same bad excuses? Let's beat them 🚀",
      "Your habits are up earlier than you. Respect the schedule ⏰",
      "Good morning! Your future self is rooting for today-you 🙌",
      "Rise and grind. Or just rise. Then grind. You know the drill 💪",
    ],
  },
  funny_inactive: {
    title: "👀 We noticed something",
    variants: [
      "Bro. It's {{time}}. Your streak misses you 😢",
      "Your habits are sitting there. Alone. Judging you silently. 📋",
      "We checked — nothing logged today. We're not mad. Just concerned 💔",
      "Your streak is {{streakCount}} days strong. Don't be the reason it ends 🔥",
      "Quick question: did you forget, or did you forget? Either way, let's go 😤",
    ],
  },
  funny_almost_done: {
    title: "🎯 So close!",
    variants: [
      "{{remaining}} habit{{s}} left. You've done harder things today.",
      "ALMOST THERE. {{remaining}} more. Do not quit now 😤",
      "The finish line is right there. {{remaining}} habit{{s}}. Go. 🏃",
      "Future you is judging present you. Don't disappoint them 👀",
    ],
  },
  funny_perfect_day: {
    title: "🐐 All habits done!",
    variants: [
      "ALL habits done. Who ARE you?! Seriously though, incredible 🐐",
      "Perfect day unlocked. You didn't have to go this hard but you did 👑",
      "Complete. Done. Finished. You absolute unit 💪",
      "Daily habits: 100%. Excuses: 0%. That's the way 🔥",
    ],
  },
  funny_late_night: {
    title: "🌙 11:45 PM check",
    variants: [
      "It's almost midnight. Log your habits or forever hold your peace 🙏",
      "15 minutes left. Your streak is watching the clock 👀",
      "Last call for habits. Don't make us send a second notification 😤",
    ],
  },
  funny_relapse: {
    title: "😅 One step back, two forward",
    variants: [
      "Junk food: 1. You: 0. Today we reset the score 🔄",
      "Yesterday happened. Today doesn't have to. Your habits forgive you 🙌",
      "The diet habit is crying. Softly. But it still believes in you 🥲",
    ],
  },
  friend_request: {
    title: "👋 New friend request",
    variants: [
      "{{senderName}} wants to be your StreakMate! Accept?",
      "{{senderName}} found you on StreakMate and wants to compete 👊",
    ],
  },
  friend_accepted: {
    title: "🎉 Friend request accepted",
    variants: [
      "{{acceptorName}} accepted your request! Time to compete 🔥",
      "You and {{acceptorName}} are now StreakMates. May the best streak win 🏆",
    ],
  },
  friend_streak_overtake: {
    title: "📈 {{friendName}} just passed you",
    variants: [
      "{{friendName}} now has a {{streakCount}} day streak. You've been overtaken 👀",
      "Leaderboard update: {{friendName}} passed you. Just saying 😏",
    ],
  },
  friend_nudge: {
    title: "👊 Nudge from {{senderName}}",
    variants: [
      "{{senderName}} is checking on your habits. They believe in you 💪",
      "{{senderName}} sent a nudge. Don't let them down 🔥",
      "Your friend {{senderName}} poked you. Time to log those habits 📋",
    ],
  },
  leaderboard_change: {
    title: "📊 Leaderboard update",
    variants: [
      "You moved to #{{rank}} on the leaderboard 📊",
      "Leaderboard shift: you're now at rank #{{rank}} 🏆",
    ],
  },
  achievement_unlocked: {
    title: "🏆 Achievement unlocked!",
    variants: [
      "{{achievementName}} — {{achievementDescription}}",
      "Badge earned: {{achievementName}} 🎖️",
    ],
  },
  level_up: {
    title: "⬆️ Level Up!",
    variants: [
      "You reached Level {{level}}! Keep going 🚀",
      "Level {{level}} unlocked. You're becoming unstoppable 👑",
      "LEVEL {{level}}. The grind is paying off 🔥",
    ],
  },
  weekly_summary: {
    title: "📊 Your week in review",
    variants: [
      "{{productiveDays}}/7 productive days this week. {{streakCount}} day streak. {{bestHabitName}} was your best habit 💪",
      "Week done: {{productiveDays}} productive days, {{streakCount}} day streak. More next week? 🎯",
    ],
  },
  monthly_report: {
    title: "📅 {{monthLabel}} summary",
    variants: [
      "{{productiveDays}}/{{totalDays}} productive days · {{successRate}}% success rate · Best streak: {{bestStreak}} days",
      "{{monthLabel}} wrapped up: {{productiveDays}} productive days, {{successRate}}% rate. {{topHabitName}} was your strongest 🏆",
    ],
  },
}

// ─── Pick a random variant and replace variables ─────────────────────────────
const interpolate = (template, variables = {}) => {
  return template.replace(/\{\{(\s*\w+\s*)\}\}/g, (_, key) => {
    const val = variables[key.trim()]
    return val !== undefined ? String(val) : `{{${key.trim()}}}`
  })
}

const pickRandom = (arr) => arr[Math.floor(Math.random() * arr.length)]

// ─── Main export ─────────────────────────────────────────────────────────────

/**
 * getNotificationCopy
 * Returns { title, body } for a notification type with variables interpolated
 *
 * First tries DB template, falls back to hardcoded
 */
export const getNotificationCopy = async (type, variables = {}) => {
  try {
    // Try DB template first
    const dbTemplate = await NotificationTemplate.findOne({ type, isActive: true }).lean()

    if (dbTemplate) {
      const body = pickRandom(dbTemplate.bodyVariants)
      return {
        title: interpolate(dbTemplate.title, variables),
        body: interpolate(body, variables),
      }
    }
  } catch {
    // DB unavailable — use fallback
  }

  // Hardcoded fallback
  const fallback = FALLBACK_TEMPLATES[type]
  if (!fallback) {
    return {
      title: 'StreakMate',
      body: 'You have a new notification',
    }
  }

  const body = pickRandom(fallback.variants)
  return {
    title: interpolate(fallback.title, variables),
    body: interpolate(body, variables),
  }
}

// ─── Sync version (no DB) — for jobs that need speed ────────────────────────
export const getNotificationCopySync = (type, variables = {}) => {
  const fallback = FALLBACK_TEMPLATES[type]
  if (!fallback) return { title: 'StreakMate', body: 'Check the app!' }

  const body = pickRandom(fallback.variants)
  return {
    title: interpolate(fallback.title, variables),
    body: interpolate(body, variables),
  }
}

export { FALLBACK_TEMPLATES }