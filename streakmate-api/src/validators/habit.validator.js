import { z } from 'zod'

const habitCategories = ['gym', 'prayer', 'study', 'diet', 'welfare', 'custom']
const activeDaysArray = z
  .array(z.number().min(0).max(6))
  .min(1, 'At least one active day required')
  .max(7)

export const createHabitSchema = z.object({
  name: z
    .string({ required_error: 'Habit name is required' })
    .min(1, 'Habit name is required')
    .max(60, 'Habit name must be at most 60 characters')
    .trim(),
  category: z.enum(habitCategories, {
    required_error: 'Category is required',
    invalid_type_error: `Category must be one of: ${habitCategories.join(', ')}`,
  }),
  icon: z.string().max(10).optional(),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, 'Color must be a valid hex code')
    .optional(),
  description: z.string().max(200).nullable().optional(),
  frequency: z.enum(['daily', 'custom']).default('daily'),
  activeDays: activeDaysArray.default([0, 1, 2, 3, 4, 5, 6]),
  startDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Start date must be YYYY-MM-DD')
    .optional(),
  completionRule: z
    .enum(['all_required', 'percentage', 'user_defined'])
    .default('all_required'),
  completionThreshold: z.number().min(1).max(100).optional(),
  reminderEnabled: z.boolean().default(false),
  reminderTimes: z
    .array(z.string().regex(/^\d{2}:\d{2}$/, 'Time must be HH:MM format'))
    .max(5, 'Max 5 reminder times')
    .optional(),
  reminderDays: activeDaysArray.optional(),
})

export const updateHabitSchema = z.object({
  name: z.string().min(1).max(60).trim().optional(),
  icon: z.string().max(10).optional(),
  color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
  description: z.string().max(200).nullable().optional(),
  frequency: z.enum(['daily', 'custom']).optional(),
  activeDays: activeDaysArray.optional(),
  endDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'End date must be YYYY-MM-DD')
    .nullable()
    .optional(),
  reminderEnabled: z.boolean().optional(),
  reminderTimes: z
    .array(z.string().regex(/^\d{2}:\d{2}$/))
    .max(5)
    .optional(),
  reminderDays: activeDaysArray.optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field required' }
)

export const updateCompletionRuleSchema = z.object({
  completionRule: z.enum(['all_required', 'percentage', 'user_defined'], {
    required_error: 'Completion rule is required',
  }),
  completionThreshold: z
    .number()
    .min(1)
    .max(100)
    .optional(),
}).refine(
  (data) => {
    if (data.completionRule === 'percentage' && !data.completionThreshold) {
      return false
    }
    return true
  },
  { message: 'completionThreshold is required when rule is "percentage"' }
)

export const reorderHabitSchema = z.object({
  displayOrder: z
    .number({ required_error: 'displayOrder is required' })
    .min(0),
})