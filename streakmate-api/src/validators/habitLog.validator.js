import { z } from 'zod'

const dateRegex = /^\d{4}-\d{2}-\d{2}$/

export const createLogSchema = z.object({
  date: z
    .string()
    .regex(dateRegex, 'Date must be YYYY-MM-DD')
    .optional(),
  loggedOffline: z.boolean().default(false),
  allowBackdate: z.boolean().default(false),
})

export const updateLogSchema = z.object({
  isCompleted: z.boolean().optional(),
  completionPercentage: z.number().min(0).max(100).optional(),
})

export const updateSubtaskResultSchema = z.object({
  isCompleted: z.boolean({ required_error: 'isCompleted is required' }),
  value: z.number().nullable().optional(),
})

export const logRangeQuerySchema = z.object({
  from: z
    .string({ required_error: 'from date is required' })
    .regex(dateRegex, 'from must be YYYY-MM-DD'),
  to: z
    .string({ required_error: 'to date is required' })
    .regex(dateRegex, 'to must be YYYY-MM-DD'),
}).refine(
  (data) => data.from <= data.to,
  { message: 'from must be before or equal to to', path: ['from'] }
)