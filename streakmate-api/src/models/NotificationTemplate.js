import mongoose from 'mongoose'

const notificationTemplateSchema = new mongoose.Schema(
  {
    // ─── Type ─────────────────────────────────────────────────────
    type: {
      type: String,
      required: true,
      unique: true,
      enum: [
        'daily_reminder', 'habit_reminder', 'streak_warning', 'end_of_day_nudge',
        'streak_milestone', 'streak_at_risk', 'streak_broken', 'streak_restored',
        'freeze_used', 'cheat_day_used', 'freeze_running_low', 'freeze_expired',
        'funny_morning', 'funny_inactive', 'funny_almost_done', 'funny_perfect_day',
        'funny_late_night', 'funny_relapse',
        'friend_request', 'friend_accepted', 'friend_streak_overtake', 'friend_nudge',
        'leaderboard_change', 'achievement_unlocked', 'level_up', 'xp_earned',
        'app_update', 'weekly_summary', 'monthly_report',
      ],
    },

    // ─── Content ──────────────────────────────────────────────────
    title: {
      type: String,
      required: true, // base title, variables replaced at send time
    },
    // multiple body variants — picked randomly at send time for engagement
    bodyVariants: {
      type: [String],
      required: true,
      validate: {
        validator: (v) => v.length >= 1,
        message: 'At least one body variant required',
      },
    },

    // ─── Variables ────────────────────────────────────────────────
    // list of placeholders used in title/bodyVariants
    // e.g. ["userName", "streakCount", "habitName"]
    variables: {
      type: [String],
      default: [],
    },

    // ─── Platform ─────────────────────────────────────────────────
    platform: {
      type: String,
      enum: ['both', 'ios', 'android'],
      default: 'both',
    },

    // ─── Meta ─────────────────────────────────────────────────────
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
)

const NotificationTemplate = mongoose.model('NotificationTemplate', notificationTemplateSchema)
export default NotificationTemplate