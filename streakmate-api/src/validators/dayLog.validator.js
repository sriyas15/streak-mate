import { z } from 'zod'

const dateRegex = /^\d{4}-\d{2}-\d{2}$/
const monthRegex = /^\d{4}-\d{2}$/

export const updateMoodSchema = z.object({
  mood: z.enum(['great', 'good', 'okay', 'bad', 'terrible'], {
    required_error: 'Mood is required',
    invalid_type_error: 'Mood must be one of: great, good, okay, bad, terrible',
  }),
})

export const updateNoteSchema = z.object({
  note: z
    .string({ required_error: 'Note is required' })
    .max(300, 'Note must be at most 300 characters'),
})

export const activateFreezeSchema = z.object({
  date: z
    .string({ required_error: 'Date is required' })
    .regex(dateRegex, 'Date must be YYYY-MM-DD'),
  reason: z
    .string()
    .max(100)
    .optional(),
})

export const activateCheatDaySchema = z.object({
  date: z
    .string({ required_error: 'Date is required' })
    .regex(dateRegex, 'Date must be YYYY-MM-DD'),
})

export const calendarQuerySchema = z.object({
  month: z
    .string({ required_error: 'Month is required' })
    .regex(monthRegex, 'Month must be YYYY-MM'),
})

export const rangeQuerySchema = z.object({
  from: z
    .string({ required_error: 'from is required' })
    .regex(dateRegex, 'from must be YYYY-MM-DD'),
  to: z
    .string({ required_error: 'to is required' })
    .regex(dateRegex, 'to must be YYYY-MM-DD'),
}).refine(
  (data) => data.from <= data.to,
  { message: 'from must be before or equal to to', path: ['from'] }
)