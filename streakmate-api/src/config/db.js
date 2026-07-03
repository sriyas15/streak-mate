import mongoose from 'mongoose'
import { env } from './env.js'

const MONGODB_OPTIONS = {
  maxPoolSize: 10,        // max connections in pool
  serverSelectionTimeoutMS: 5000,  // fail fast if mongo not reachable
  socketTimeoutMS: 45000,
  family: 4,              // force IPv4
}

export const connectDB = async () => {
  try {
    const conn = await mongoose.connect(env.MONGODB_URI, MONGODB_OPTIONS)
    console.log(`✅ MongoDB connected: ${conn.connection.host}`)
    attachListeners()
  } catch (err) {
    console.error(`❌ MongoDB connection errors: ${err}`)
    process.exit(1)
  }
}

// ─── Lifecycle listeners ────────────────────────────────────────────────────
const attachListeners = () => {
  mongoose.connection.on('disconnected', () => {
    console.warn('⚠️  MongoDB disconnected — retrying...')
  })

  mongoose.connection.on('reconnected', () => {
    console.log('✅ MongoDB reconnected')
  })

  mongoose.connection.on('error', (err) => {
    console.error(`❌ MongoDB error: ${err.message}`)
  })
}

// ─── Graceful shutdown ──────────────────────────────────────────────────────
export const disconnectDB = async () => {
  await mongoose.connection.close()
  console.log('🔌 MongoDB connection closed')
}