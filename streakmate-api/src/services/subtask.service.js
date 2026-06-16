import { Subtask, Habit } from '../models/index.js'

export const subtaskService = {
    // ── Get all subtasks for a habit ─────────────────────────────────
    getSubtasks: async (userId, habitId) => {
        await verifyHabitOwnership(userId, habitId)

        return Subtask.find({ habitId, userId, isActive: true })
            .sort({ displayOrder: 1 })
            .lean()
    },

    // ── Create subtask ───────────────────────────────────────────────
    createSubtask: async (userId, habitId, body) => {
        await verifyHabitOwnership(userId, habitId)

        const count = await Subtask.countDocuments({ habitId, userId, isActive: true })
        if (count >= 10) throwBadRequest('Maximum 10 subtasks per habit')

        const subtask = await Subtask.create({
            habitId,
            userId,
            name: body.name,
            icon: body.icon || null,
            inputType: body.inputType || 'checkbox',
            unit: body.unit || null,
            targetValue: body.targetValue || null,
            isRequired: body.isRequired !== undefined ? body.isRequired : true,
            displayOrder: body.displayOrder !== undefined ? body.displayOrder : count,
        })

        return subtask
    },

    // ── Update subtask ───────────────────────────────────────────────
    updateSubtask: async (userId, habitId, subtaskId, body) => {
        await verifyHabitOwnership(userId, habitId)

        const allowed = [
            'name', 'icon', 'inputType', 'unit',
            'targetValue', 'isRequired', 'displayOrder', 'isActive',
        ]
        const filtered = {}
        for (const key of allowed) {
            if (body[key] !== undefined) filtered[key] = body[key]
        }

        const subtask = await Subtask.findOneAndUpdate(
            { _id: subtaskId, habitId, userId },
            filtered,
            { new: true, runValidators: true }
        )

        if (!subtask) throwNotFound('Subtask')
        return subtask
    },

    // ── Delete subtask (soft delete) ─────────────────────────────────
    deleteSubtask: async (userId, habitId, subtaskId) => {
        await verifyHabitOwnership(userId, habitId)

        const subtask = await Subtask.findOneAndUpdate(
            { _id: subtaskId, habitId, userId },
            { isActive: false },
            { new: true }
        )

        if (!subtask) throwNotFound('Subtask')
    },

    // ── Reorder subtasks ─────────────────────────────────────────────
    // body.order: [{ subtaskId, displayOrder }]
    reorderSubtasks: async (userId, habitId, order) => {
        await verifyHabitOwnership(userId, habitId)

        const updates = order.map(({ subtaskId, displayOrder }) =>
            Subtask.findOneAndUpdate(
                { _id: subtaskId, habitId, userId },
                { displayOrder },
            )
        )

        await Promise.all(updates)
    },
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
const verifyHabitOwnership = async (userId, habitId) => {
    const habit = await Habit.findOne({ _id: habitId, userId }).lean()
    if (!habit) throwNotFound('Habit')
}

const throwNotFound = (entity) => {
    const err = new Error(`${entity} not found`)
    err.statusCode = 404
    throw err
}

const throwBadRequest = (message) => {
    const err = new Error(message)
    err.statusCode = 400
    throw err
}