import mongoose from 'mongoose'

const dayLogSchema = new mongoose.Schema(
  {
    // ─── Ownership ────────────────────────────────────────────────
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // ─── Date ─────────────────────────────────────────────────────
    date: {
      type: String, // "2024-06-04" — one doc per user per day
      required: true,
      index: true,
    },

    // ─── Day Result ───────────────────────────────────────────────
    isProductiveDay: {
      type: Boolean,
      default: false, // true when all active habits completed
    },
    productivityScore: {
      type: Number,
      min: 0,
      max: 100,
      default: 0, // percentage of habits completed
    },
    totalHabits: {
      type: Number,
      default: 0,
    },
    completedHabits: {
      type: Number,
      default: 0,
    },
    skippedHabits: {
      type: Number,
      default: 0,
    },

    // ─── Freeze / Cheat Day ───────────────────────────────────────
    isFreezeDay: {
      type: Boolean,
      default: false,
    },
    isCheatDay: {
      type: Boolean,
      default: false,
    },
    freezeReason: {
      type: String,
      maxlength: 100,
      default: null,
    },

    // ─── Optional User Input ──────────────────────────────────────
    mood: {
      type: String,
      enum: ['great', 'good', 'okay', 'bad', 'terrible', null],
      default: null,
    },
    note: {
      type: String,
      maxlength: 300,
      default: null,
    },

    // ─── Sync ─────────────────────────────────────────────────────
    resolvedAt: {
      type: Date,
      default: null, // when midnight job finalised this day
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
dayLogSchema.index({ userId: 1, date: 1 }, { unique: true }) // one per user per day
dayLogSchema.index({ userId: 1, isProductiveDay: 1 })
dayLogSchema.index({ userId: 1, isFreezeDay: 1 })

const DayLog = mongoose.model('DayLog', dayLogSchema)
export default DayLog