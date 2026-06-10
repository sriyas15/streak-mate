import dotenv from 'dotenv'
import { z } from 'zod'

dotenv.config();

const envSchema = z.object({
  // ─── App ──────────────────────────────────────────────────────
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  PORT: z
    .string()
    .default('5000')
    .transform(Number),
  API_VERSION: z
    .string()
    .default('v1'),
  CLIENT_URL: z
    .string()
    .url('CLIENT_URL must be a valid URL'),

  // ─── MongoDB ──────────────────────────────────────────────────
  MONGODB_URI: z
    .string()
    .min(1, 'MONGODB_URI is required')
    .startsWith('mongodb', 'MONGODB_URI must be a valid MongoDB connection string'),

  // ─── JWT ──────────────────────────────────────────────────────
  JWT_ACCESS_SECRET: z
    .string()
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_REFRESH_SECRET: z
    .string()
    .min(32, 'JWT_REFRESH_SECRET must be at least 32 characters'),
  JWT_ACCESS_EXPIRES_IN: z
    .string()
    .default('15m'),
  JWT_REFRESH_EXPIRES_IN: z
    .string()
    .default('30d'),

  // ─── Redis ────────────────────────────────────────────────────
  REDIS_HOST: z
    .string()
    .default('127.0.0.1'),
  REDIS_PORT: z
    .string()
    .default('6379')
    .transform(Number),
  REDIS_PASSWORD: z
    .string()
    .optional(),
  REDIS_URL: z
    .string()
    .optional(), // used in production (Railway / Render Redis URL)

  // ─── Firebase / FCM ───────────────────────────────────────────
  FIREBASE_PROJECT_ID: z
    .string()
    .min(1, 'FIREBASE_PROJECT_ID is required'),
  FIREBASE_CLIENT_EMAIL: z
    .string()
    .email('FIREBASE_CLIENT_EMAIL must be a valid email'),
  FIREBASE_PRIVATE_KEY: z
    .string()
    .min(1, 'FIREBASE_PRIVATE_KEY is required'),

  // ─── BullMQ ───────────────────────────────────────────────────
  BULL_BOARD_USERNAME: z
    .string()
    .default('admin'),
  BULL_BOARD_PASSWORD: z
    .string()
    .min(8, 'BULL_BOARD_PASSWORD must be at least 8 characters')
    .default('admin1234'),

  // ─── Rate Limiting ────────────────────────────────────────────
  RATE_LIMIT_MAX: z
    .string()
    .default('100')
    .transform(Number),
  RATE_LIMIT_WINDOW_MS: z
    .string()
    .default('60000')
    .transform(Number), // 1 minute

  // ─── Bcrypt ───────────────────────────────────────────────────
  BCRYPT_SALT_ROUNDS: z
    .string()
    .default('12')
    .transform(Number),

  // ─── Email (future — password reset, verification) ────────────
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().optional().transform((v) => (v ? Number(v) : undefined)),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  EMAIL_FROM: z.string().optional(),

  // ─── Cloudinary (profile pictures) ───────────────────────────
  CLOUDINARY_CLOUD_NAME: z.string().optional(),
  CLOUDINARY_API_KEY: z.string().optional(),
  CLOUDINARY_API_SECRET: z.string().optional(),
})

// ─── Parse & validate on startup ────────────────────────────────────────────
const parsed = envSchema.safeParse(process.env)

if (!parsed.success) {
  console.error('❌ Invalid environment variables:')
  parsed.error.errors.forEach((err) => {
    console.error(`${err.path.join('.')} — ${err.message}`)
  })
  process.exit(1) // hard stop — never start with bad config
}

export const env = parsed.data