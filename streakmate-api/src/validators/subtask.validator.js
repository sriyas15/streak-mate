import { z } from 'zod'

const inputTypes = ['checkbox', 'quantity', 'timer']
const units = ['g', 'kg', 'ml', 'l', 'min', 'hrs', 'pages', 'steps', 'km', 'kcal', 'reps']

export const createSubtaskSchema = z.object({
  name: z
    .string({ required_error: 'Subtask name is required' })
    .min(1, 'Subtask name is required')
    .max(80, 'Subtask name must be at most 80 characters')
    .trim(),
  icon: z.string().max(10).nullable().optional(),
  inputType: z.enum(inputTypes).default('checkbox'),
  unit: z.enum(units).nullable().optional(),
  targetValue: z.number().positive().nullable().optional(),
  isRequired: z.boolean().default(true),
  displayOrder: z.number().min(0).optional(),
}).refine(
  (data) => {
    // unit is required when inputType is quantity or timer
    if (['quantity', 'timer'].includes(data.inputType) && !data.unit) {
      return false
    }
    return true
  },
  { message: 'Unit is required for quantity and timer input types', path: ['unit'] }
)

export const updateSubtaskSchema = z.object({
  name: z.string().min(1).max(80).trim().optional(),
  icon: z.string().max(10).nullable().optional(),
  inputType: z.enum(inputTypes).optional(),
  unit: z.enum(units).nullable().optional(),
  targetValue: z.number().positive().nullable().optional(),
  isRequired: z.boolean().optional(),
  displayOrder: z.number().min(0).optional(),
  isActive: z.boolean().optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field required' }
)

export const reorderSubtasksSchema = z.object({
  order: z
    .array(
      z.object({
        subtaskId: z
          .string()
          .regex(/^[a-f\d]{24}$/i, 'Invalid subtask ID'),
        displayOrder: z.number().min(0),
      })
    )
    .min(1, 'Order array cannot be empty'),
})