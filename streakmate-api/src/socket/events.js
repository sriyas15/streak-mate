/**
 * Socket event name constants
 * Used by both server handlers and Flutter client
 * Keep in sync with Flutter socket_events.dart
 */
export const SOCKET_EVENTS = {
  // ─── Habit ────────────────────────────────────────────────────
  HABIT_COMPLETED:          'habit:completed',
  HABIT_UNCOMPLETED:        'habit:uncompleted',

  // ─── Streak ───────────────────────────────────────────────────
  STREAK_UPDATED:           'streak:updated',
  STREAK_BROKEN:            'streak:broken',
  STREAK_MILESTONE:         'streak:milestone',
  STREAK_RESTORED:          'streak:restored',

  // ─── Friends ──────────────────────────────────────────────────
  FRIEND_REQUEST_RECEIVED:  'friend:request:received',
  FRIEND_ACCEPTED:          'friend:accepted',
  FRIEND_STREAK_OVERTAKE:   'friend:streak:overtake',
  SEND_NUDGE:               'friend:nudge:send',
  RECEIVE_NUDGE:            'friend:nudge:receive',

  // ─── Leaderboard ──────────────────────────────────────────────
  LEADERBOARD_UPDATED:      'leaderboard:updated',

  // ─── Calendar ──────────────────────────────────────────────
  CALENDAR_UPDATED: 'calendar:updated',

  // ─── Notifications ────────────────────────────────────────────
  NEW_NOTIFICATION:         'notification:new',

  // ─── Gamification ─────────────────────────────────────────────
  XP_EARNED:                'gamification:xp',
  LEVEL_UP:                 'gamification:level_up',
  ACHIEVEMENT_UNLOCKED:     'gamification:achievement',

  // ─── System ───────────────────────────────────────────────────
  PING:                     'ping',
  PONG:                     'pong',
  ERROR:                    'error',
}