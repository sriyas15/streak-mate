import mongoose from 'mongoose'

const streakRunSchema = new mongoose.Schema(
  {
    startDate: { type: String, required: true }, // "2024-05-01"
    endDate: { type: String, default: null },     // null if ongoing
    count: { type: Number, required: true },
    endReason: {
      type: String,
      enum: ['missed', 'freeze_used', 'cheat_used', 'ongoing'],
      default: 'ongoing',
    },
  },
  { _id: false }
)

const streakSchema = new mongoose.Schema(
  {
    // ─── Ownership ────────────────────────────────────────────────
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    habitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Habit',
      default: null, // null = overall app streak
      index: true,
    },

    // ─── Current Run ──────────────────────────────────────────────
    currentStreakStart: {
      type: String, // "2024-05-10"
      default: null,
    },
    currentStreakEnd: {
      type: String, // null if ongoing
      default: null,
    },
    currentStreakCount: {
      type: Number,
      default: 0,
    },

    // ─── Best Ever ────────────────────────────────────────────────
    bestStreakStart: {
      type: String,
      default: null,
    },
    bestStreakEnd: {
      type: String,
      default: null,
    },
    bestStreakCount: {
      type: Number,
      default: 0,
    },

    // ─── History ──────────────────────────────────────────────────
    streakHistory: {
      type: [streakRunSchema],
      default: [],
    },

    // ─── Freeze Usage in Current Streak ───────────────────────────
    freezesUsedInCurrentStreak: {
      type: Number,
      default: 0,
    },
    cheatDaysUsedInCurrentStreak: {
      type: Number,
      default: 0,
    },

    // ─── Stats ────────────────────────────────────────────────────
    totalDaysTracked: {
      type: Number,
      default: 0,
    },
    totalCompletedDays: {
      type: Number,
      default: 0,
    },
    completionRate: {
      type: Number,
      min: 0,
      max: 100,
      default: 0, // percentage
    },

    // ─── Meta ─────────────────────────────────────────────────────
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
streakSchema.index({ userId: 1, habitId: 1 }, { unique: true }) // one streak doc per habit per user
streakSchema.index({ userId: 1, currentStreakCount: -1 })        // for leaderboard queries

const Streak = mongoose.model('Streak', streakSchema)
export default Streak