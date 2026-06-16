import { z } from 'zod'

const dateRegex = /^\d{4}-\d{2}-\d{2}$/

export const activateFreezeSchema = z.object({
  date: z
    .string({ required_error: 'Date is required' })
    .regex(dateRegex, 'Date must be YYYY-MM-DD'),
  reason: z
    .string()
    .max(100, 'Reason must be at most 100 characters')
    .optional(),
})

export const activateCheatDaySchema = z.object({
  date: z
    .string({ required_error: 'Date is required' })
    .regex(dateRegex, 'Date must be YYYY-MM-DD'),
})