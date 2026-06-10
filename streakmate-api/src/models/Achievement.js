import mongoose from 'mongoose'

// ─── Achievement Definition (global, admin-seeded) ───────────────────────────
const achievementSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      maxlength: 200,
    },
    icon: {
      type: String,
      required: true, // emoji or asset path
    },
    badgeColor: {
      type: String,
      default: '#F5A623',
    },

    // ─── Type & Condition ─────────────────────────────────────────
    type: {
      type: String,
      enum: ['streak', 'completion', 'social', 'special'],
      required: true,
    },
    condition: {
      type: String,
      required: true,
      // e.g. "streak_7" | "streak_30" | "streak_100"
      //      "perfect_week" | "perfect_month"
      //      "all_habits_30_days" | "first_habit_complete"
      //      "add_5_friends" | "nudge_sent"
    },
    conditionValue: {
      type: Number,
      default: null, // e.g. 7 for streak_7
    },

    // ─── Reward ───────────────────────────────────────────────────
    xpReward: {
      type: Number,
      default: 50,
    },

    // ─── Meta ─────────────────────────────────────────────────────
    isActive: {
      type: Boolean,
      default: true,
    },
    displayOrder: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
)

// ─── User Achievement (junction — which user unlocked what) ──────────────────
const userAchievementSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    achievementId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Achievement',
      required: true,
    },
    unlockedAt: {
      type: Date,
      default: Date.now,
    },
    seen: {
      type: Boolean,
      default: false, // false until user opens achievements screen
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
userAchievementSchema.index({ userId: 1, achievementId: 1 }, { unique: true })
userAchievementSchema.index({ userId: 1, seen: 1 })

export const Achievement = mongoose.model('Achievement', achievementSchema)
export const UserAchievement = mongoose.model('UserAchievement', userAchievementSchema)