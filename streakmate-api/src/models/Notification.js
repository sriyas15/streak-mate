import mongoose from 'mongoose'

const notificationSchema = new mongoose.Schema(
  {
    // ─── Ownership ────────────────────────────────────────────────
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // ─── Context ──────────────────────────────────────────────────
    habitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Habit',
      default: null,
    },
    triggeredByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null, // for friend nudges, overtake notifs
    },

    // ─── Type ─────────────────────────────────────────────────────
    type: {
      type: String,
      required: true,
      enum: [
        // Reminders
        'daily_reminder',
        'habit_reminder',
        'streak_warning',
        'end_of_day_nudge',

        // Streak
        'streak_milestone',
        'streak_at_risk',
        'streak_broken',
        'streak_restored',

        // Freeze / Cheat
        'freeze_used',
        'cheat_day_used',
        'freeze_running_low',
        'freeze_expired',

        // Funny / Engagement
        'funny_morning',
        'funny_inactive',
        'funny_almost_done',
        'funny_perfect_day',
        'funny_late_night',
        'funny_relapse',

        // Social
        'friend_request',
        'friend_accepted',
        'friend_streak_overtake',
        'friend_nudge',
        'leaderboard_change',

        // Achievement
        'achievement_unlocked',
        'level_up',
        'xp_earned',

        // System
        'app_update',
        'weekly_summary',
        'monthly_report',
      ],
    },

    // ─── Content ──────────────────────────────────────────────────
    title: {
      type: String,
      required: true,
      maxlength: 100,
    },
    body: {
      type: String,
      required: true,
      maxlength: 300,
    },
    imageUrl: {
      type: String,
      default: null,
    },

    // ─── Deep Link ────────────────────────────────────────────────
    deepLinkScreen: {
      type: String,
      enum: ['Home', 'HabitDetail', 'Analytics', 'Calendar', 'Friends', 'Leaderboard', 'Achievements', 'Profile', null],
      default: null,
    },
    deepLinkParams: {
      type: mongoose.Schema.Types.Mixed,
      default: null, // e.g. { habitId: "xyz" }
    },

    // ─── Delivery ─────────────────────────────────────────────────
    scheduledAt: {
      type: Date,
      default: null,
    },
    sentAt: {
      type: Date,
      default: null,
    },
    isDelivered: {
      type: Boolean,
      default: false,
    },
    isSeen: {
      type: Boolean,
      default: false,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    failureReason: {
      type: String,
      default: null,
    },

    // ─── FCM ──────────────────────────────────────────────────────
    fcmToken: {
      type: String,
      default: null,
    },
    fcmMessageId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
notificationSchema.index({ userId: 1, createdAt: -1 })
notificationSchema.index({ userId: 1, isRead: 1 })
notificationSchema.index({ userId: 1, isSeen: 1 })
notificationSchema.index({ scheduledAt: 1, isDelivered: 1 }) // for scheduler job queries

const Notification = mongoose.model('Notification', notificationSchema)
export default Notification