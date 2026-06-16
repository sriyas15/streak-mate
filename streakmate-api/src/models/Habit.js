import mongoose from 'mongoose'

const habitSchema = new mongoose.Schema(
  {
    // ─── Ownership ────────────────────────────────────────────────
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // ─── Basic Info ───────────────────────────────────────────────
    name: {
      type: String,
      required: [true, 'Habit name is required'],
      trim: true,
      maxlength: 60,
    },
    category: {
      type: String,
      enum: ['gym', 'prayer', 'study', 'diet', 'welfare', 'custom'],
      required: true,
    },
    icon: {
      type: String,
      default: '⭐',
    },
    color: {
      type: String,
      default: '#1D9E75',
    },
    description: {
      type: String,
      maxlength: 200,
      default: null,
    },
    subtasks: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Subtask'
  },

    // ─── Schedule ─────────────────────────────────────────────────
    frequency: {
      type: String,
      enum: ['daily', 'custom'],
      default: 'daily',
    },
    activeDays: {
      type: [Number], // 0=Sun, 1=Mon ... 6=Sat
      default: [0, 1, 2, 3, 4, 5, 6],
    },
    startDate: {
      type: String, // "2024-06-04"
      required: true,
    },
    endDate: {
      type: String,
      default: null,
    },

    // ─── Completion Rule ──────────────────────────────────────────
    completionRule: {
      type: String,
      enum: ['all_required', 'percentage', 'user_defined'],
      default: 'all_required',
    },
    completionThreshold: {
      type: Number,
      min: 1,
      max: 100,
      default: 100, // used when completionRule = 'percentage'
    },

    // ─── Streak ───────────────────────────────────────────────────
    currentStreak: {
      type: Number,
      default: 0,
    },
    bestStreak: {
      type: Number,
      default: 0,
    },
    totalCompletions: {
      type: Number,
      default: 0,
    },
    lastCompletedDate: {
      type: String, // "2024-06-04"
      default: null,
    },

    // ─── Reminder ─────────────────────────────────────────────────
    reminderEnabled: {
      type: Boolean,
      default: false,
    },
    reminderTimes: {
      type: [String], // ["07:00", "13:00"]
      default: [],
    },
    reminderDays: {
      type: [Number], // subset of activeDays
      default: [0, 1, 2, 3, 4, 5, 6],
    },

    // ─── Display ──────────────────────────────────────────────────
    displayOrder: {
      type: Number,
      default: 0,
    },

    // ─── Meta ─────────────────────────────────────────────────────
    isActive: {
      type: Boolean,
      default: true,
    },
    isArchived: {
      type: Boolean,
      default: false,
    },
    isCustom: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
habitSchema.index({ userId: 1, isActive: 1 })
habitSchema.index({ userId: 1, category: 1 })
habitSchema.index({ userId: 1, isArchived: 1 })

const Habit = mongoose.model('Habit', habitSchema)
export default Habit