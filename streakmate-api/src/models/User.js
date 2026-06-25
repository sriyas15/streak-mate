import mongoose from 'mongoose'
import bcrypt from 'bcrypt'

const userSchema = new mongoose.Schema(
  {
    // ─── Basic Info ───────────────────────────────────────────────
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: 2,
      maxlength: 50,
    },
    username: {
      type: String,
      required: [true, 'Username is required'],
      trim: true,
      lowercase: true,
      minlength: 3,
      maxlength: 30,
      match: [/^[a-z0-9_]+$/, 'Username can only contain letters, numbers and underscores'],
    },
    
    email: {
      type: String,
      required: [true, 'Email is required'],
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
    },
    password: {
      type: String,
      minlength: 8,
      select: false, // never returned in queries by default
    },
    profilePicture: {
      type: String,
      default: null,
    },
    bio: {
      type: String,
      maxlength: 150,
      default: null,
    },
    timezone: {
      type: String,
      default: 'Asia/Kolkata',
    },

    // ─── Onboarding ───────────────────────────────────────────────
    onboardingCompleted: {
      type: Boolean,
      default: false,
    },
    onboardingStep: {
      type: Number,
      default: 1, // 1=goal, 2=habits, 3=subtasks, 4=reminders, 5=done
    },
    selectedGoal: {
      type: String,
      enum: ['fitness', 'spiritual', 'study', 'productivity', 'overall'],
      default: null,
    },

    // ─── Streak Meta ──────────────────────────────────────────────
    currentStreakDays: {
      type: Number,
      default: 0,
    },
    bestStreakDays: {
      type: Number,
      default: 0,
    },
    lastProductiveDate: {
      type: String, // "2024-06-04" — stored as string for timezone safety
      default: null,
    },

    // ─── Gamification ─────────────────────────────────────────────
    level: {
      type: Number,
      default: 1,
    },
    xpPoints: {
      type: Number,
      default: 0,
    },
    xpToNextLevel: {
      type: Number,
      default: 100,
    },

    // ─── Freeze & Cheat Day ───────────────────────────────────────
    totalFreezesAlloted: {
      type: Number,
      default: 3, // resets monthly
    },
    freezesUsed: {
      type: Number,
      default: 0,
    },
    freezesRemaining: {
      type: Number,
      default: 3,
    },
    cheatDaysAlloted: {
      type: Number,
      default: 2,
    },
    cheatDaysUsed: {
      type: Number,
      default: 0,
    },
    cheatDaysRemaining: {
      type: Number,
      default: 2,
    },
    freezeResetDate: {
      type: String, // "2024-07-01" — first of every month
      default: null,
    },

    // ─── Social ───────────────────────────────────────────────────
    friendIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    friendRequestsSent: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    friendRequestsReceived: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],

    // ─── Auth ─────────────────────────────────────────────────────
    authProvider: {
      type: String,
      enum: ['email', 'google', 'apple'],
      default: 'email',
    },
    googleId: {
      type: String,
      default: null,
    },
    appleId: {
      type: String,
      default: null,
    },
    refreshToken: {
      type: String,
      select: false,
      default: null,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationToken: {
      type: String,
      select: false,
      default: null,
    },
    emailVerificationExpiry: {
      type: Date,
      select: false,
      default: null,
    },
    passwordResetToken: {
      type: String,
      select: false,
      default: null,
    },
    passwordResetExpiry: {
      type: Date,
      select: false,
      default: null,
    },

    // ─── Settings ─────────────────────────────────────────────────
    notificationsEnabled: {
      type: Boolean,
      default: true,
    },
    reminderSoundEnabled: {
      type: Boolean,
      default: true,
    },
    theme: {
      type: String,
      enum: ['dark', 'light'],
      default: 'dark',
    },
    language: {
      type: String,
      default: 'en',
    },

    // ─── Account Status ───────────────────────────────────────────
    isActive: {
      type: Boolean,
      default: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
    lastActiveAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
userSchema.index({ email: 1 })
userSchema.index({ username: 1 })
userSchema.index({ isDeleted: 1, isActive: 1 })

// ─── Hash password before save ──────────────────────────────────────────────
userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return 
  this.password = await bcrypt.hash(this.password, 12)
})

// ─── Compare password ───────────────────────────────────────────────────────
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password)
}

// ─── Never return deleted users ─────────────────────────────────────────────
userSchema.pre(/^find/, function (next) {
  this.where({ isDeleted: false })
})

const User = mongoose.model('User', userSchema)
export default User