import mongoose from 'mongoose'

const subtaskSchema = new mongoose.Schema(
  {
    // ─── Ownership ────────────────────────────────────────────────
    habitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Habit',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    // ─── Basic Info ───────────────────────────────────────────────
    name: {
      type: String,
      required: [true, 'Subtask name is required'],
      trim: true,
      maxlength: 80,
    },
    icon: {
      type: String,
      default: null,
    },

    // ─── Input Type ───────────────────────────────────────────────
    inputType: {
      type: String,
      enum: ['checkbox', 'quantity', 'timer'],
      default: 'checkbox',
    },
    unit: {
      type: String,
      enum: ['g', 'kg', 'ml', 'l', 'min', 'hrs', 'pages', 'steps', 'km', 'kcal', 'reps', null],
      default: null, // only used when inputType = 'quantity' or 'timer'
    },
    targetValue: {
      type: Number,
      default: null, // e.g. 2000 for 2000ml water
    },

    // ─── Required Flag ────────────────────────────────────────────
    isRequired: {
      type: Boolean,
      default: true,
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
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
subtaskSchema.index({ habitId: 1, displayOrder: 1 })
subtaskSchema.index({ userId: 1 })

const Subtask = mongoose.model('Subtask', subtaskSchema)
export default Subtask