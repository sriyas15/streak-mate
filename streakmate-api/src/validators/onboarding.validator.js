import { z } from 'zod'

const habitCategories = ['gym', 'prayer', 'study', 'diet', 'welfare', 'custom']

export const setGoalSchema = z.object({
  selectedGoal: z.enum(
    ['fitness', 'spiritual', 'study', 'productivity', 'wellness', 'overall'],
    { required_error: 'Goal is required' }
  ),
})

export const selectHabitsSchema = z.object({
  categories: z
    .array(z.enum(habitCategories))
    .min(1, 'Select at least one habit category')
    .max(6, 'Max 6 categories'),
})

export const configureSubtasksSchema = z.object({
  habitSubtasks: z
    .array(
      z.object({
        habitId: z
          .string({ required_error: 'Habit ID is required' })
          .regex(/^[a-f\d]{24}$/i, 'Invalid habit ID'),
        // subtaskIds the user chose to keep enabled
        enabledSubtaskIds: z
          .array(z.string().regex(/^[a-f\d]{24}$/i))
          .optional(),
        // Custom subtasks added during onboarding
        customSubtasks: z
          .array(
            z.object({
              name: z.string().min(1).max(80).trim(),
              inputType: z.enum(['checkbox', 'quantity', 'timer']).default('checkbox'),
              unit: z.string().optional(),
              targetValue: z.number().positive().optional(),
              isRequired: z.boolean().default(true),
            })
          )
          .optional(),
      })
    )
    .min(1, 'At least one habit configuration required'),
})

export const setRemindersSchema = z.object({
  reminders: z
    .array(
      z.object({
        habitId: z
          .string({ required_error: 'Habit ID is required' })
          .regex(/^[a-f\d]{24}$/i, 'Invalid habit ID'),
        times: z
          .array(z.string().regex(/^\d{2}:\d{2}$/, 'Time must be HH:MM'))
          .min(1, 'At least one time required')
          .max(5),
        days: z
          .array(z.number().min(0).max(6))
          .default([0, 1, 2, 3, 4, 5, 6]),
      })
    )
    .optional()
    .default([]),
})