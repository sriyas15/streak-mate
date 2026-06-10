import mongoose from 'mongoose'

const appConfigSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      // e.g.
      // "default_freezes_per_month"     → 3
      // "default_cheat_days_per_month"  → 2
      // "max_habits_per_user"           → 10
      // "xp_per_productive_day"         → 50
      // "xp_per_habit_complete"         → 10
      // "streak_warning_hour"           → 21  (9PM)
      // "end_of_day_resolve_hour"       → 0   (midnight)
      // "min_app_version_ios"           → "1.0.0"
      // "min_app_version_android"       → "1.0.0"
      // "maintenance_mode"              → false
    },
    value: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    description: {
      type: String,
      maxlength: 200,
      default: null,
    },
    isPublic: {
      type: Boolean,
      default: true, // false = backend only, never sent to client
    },
  },
  {
    timestamps: true,
  }
)

const AppConfig = mongoose.model('AppConfig', appConfigSchema)
export default AppConfig