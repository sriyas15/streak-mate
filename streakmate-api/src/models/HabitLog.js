import mongoose from 'mongoose'

const subtaskResultSchema = new mongoose.Schema(
  {
    subtaskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Subtask',
      required: true,
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Number,
      default: null, // for quantity/timer inputTypes
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  { _id: false }
)

const habitLogSchema = new mongoose.Schema(
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
      required: true,
      index: true,
    },

    // ─── Date ─────────────────────────────────────────────────────
    date: {
      type: String, // "2024-06-04"
      required: true,
      index: true,
    },

    // ─── Completion ───────────────────────────────────────────────
    isCompleted: {
      type: Boolean,
      default: false,
    },
    completionPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    completedAt: {
      type: Date,
      default: null,
    },

    // ─── Subtask Results ──────────────────────────────────────────
    subtaskResults: {
      type: [subtaskResultSchema],
      default: [],
    },

    // ─── Streak Context ───────────────────────────────────────────
    streakDayNumber: {
      type: Number,
      default: null, // which day number in the streak this was
    },

    // ─── Sync ─────────────────────────────────────────────────────
    loggedOffline: {
      type: Boolean,
      default: false,
    },
    syncedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
habitLogSchema.index({ userId: 1, date: 1 })
habitLogSchema.index({ habitId: 1, date: 1 })
habitLogSchema.index({ userId: 1, habitId: 1, date: 1 }, { unique: true }) // one log per habit per day
habitLogSchema.index({ userId: 1, isCompleted: 1 })

const HabitLog = mongoose.model('HabitLog', habitLogSchema)
export default HabitLog