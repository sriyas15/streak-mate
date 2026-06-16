import { z } from 'zod'

export const registerTokenSchema = z.object({
  token: z
    .string({ required_error: 'FCM token is required' })
    .min(10, 'Invalid FCM token'),
  device: z.enum(['ios', 'android'], {
    required_error: 'Device type is required',
  }),
  deviceId: z.string().optional(),
  deviceModel: z.string().optional(),
  appVersion: z.string().optional(),
})

export const removeTokenSchema = z.object({
  token: z
    .string({ required_error: 'FCM token is required' })
    .min(10, 'Invalid FCM token'),
})

export const updatePreferencesSchema = z.object({
  notificationsEnabled: z.boolean().optional(),
  reminderSoundEnabled: z.boolean().optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one preference required' }
)

export const createReminderSchema = z.object({
  habitId: z
    .string({ required_error: 'Habit ID is required' })
    .regex(/^[a-f\d]{24}$/i, 'Invalid habit ID'),
  times: z
    .array(z.string().regex(/^\d{2}:\d{2}$/, 'Time must be HH:MM'))
    .min(1, 'At least one reminder time required')
    .max(5, 'Max 5 reminder times'),
  days: z
    .array(z.number().min(0).max(6))
    .optional(),
})

export const updateReminderSchema = z.object({
  enabled: z.boolean().optional(),
  times: z
    .array(z.string().regex(/^\d{2}:\d{2}$/))
    .min(1)
    .max(5)
    .optional(),
  days: z
    .array(z.number().min(0).max(6))
    .optional(),
})