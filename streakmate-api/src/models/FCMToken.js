import mongoose from 'mongoose'

const fcmTokenSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    token: {
      type: String,
      required: true
    },
    device: {
      type: String,
      enum: ['ios', 'android'],
      required: true,
    },
    deviceId: {
      type: String,
      default: null, // unique device identifier
    },
    deviceModel: {
      type: String,
      default: null, // e.g. "iPhone 15", "Pixel 8"
    },
    appVersion: {
      type: String,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastUsedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
fcmTokenSchema.index({ userId: 1, isActive: 1 })
fcmTokenSchema.index({ token: 1 })

const FCMToken = mongoose.model('FCMToken', fcmTokenSchema)
export default FCMToken