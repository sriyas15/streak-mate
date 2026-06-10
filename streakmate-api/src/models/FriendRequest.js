import mongoose from 'mongoose'

const friendRequestSchema = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'cancelled'],
      default: 'pending',
      index: true,
    },
    sentAt: {
      type: Date,
      default: Date.now,
    },
    respondedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
)

// ─── Indexes ────────────────────────────────────────────────────────────────
friendRequestSchema.index({ senderId: 1, receiverId: 1 }, { unique: true }) // no duplicate requests
friendRequestSchema.index({ receiverId: 1, status: 1 })
friendRequestSchema.index({ senderId: 1, status: 1 })

const FriendRequest = mongoose.model('FriendRequest', friendRequestSchema)
export default FriendRequest