import { z } from 'zod'

export const updateProfileSchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(50)
    .trim()
    .optional(),
  username: z
    .string()
    .min(3)
    .max(30)
    .regex(/^[a-z0-9_]+$/, 'Username can only contain lowercase letters, numbers and underscores')
    .toLowerCase()
    .trim()
    .optional(),
  bio: z
    .string()
    .max(150, 'Bio must be at most 150 characters')
    .nullable()
    .optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field required' }
)

export const updateSettingsSchema = z.object({
  notificationsEnabled: z.boolean().optional(),
  reminderSoundEnabled: z.boolean().optional(),
  theme: z.enum(['dark', 'light']).optional(),
  language: z.string().min(2).max(5).optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one setting required' }
)

export const updateTimezoneSchema = z.object({
  timezone: z
    .string({ required_error: 'Timezone is required' })
    .min(1, 'Timezone is required'),
  // Flutter sends IANA timezone strings e.g. "Asia/Kolkata"
})