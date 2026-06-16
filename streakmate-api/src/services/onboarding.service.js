import { User, Habit, Subtask } from '../models/index.js'
import { HABIT_TEMPLATES } from '../utils/constants.js'

export const onboardingService = {
  // ── Get onboarding status ────────────────────────────────────────
  getStatus: async (userId) => {
    const user = await User.findById(userId)
      .select('onboardingCompleted onboardingStep selectedGoal')
      .lean()
    if (!user) throwNotFound('User')

    return {
      onboardingCompleted: user.onboardingCompleted,
      onboardingStep:      user.onboardingStep,
      selectedGoal:        user.selectedGoal,
    }
  },

  // ── Step 1 — Set goal ────────────────────────────────────────────
  setGoal: async (userId, selectedGoal) => {
    await User.findByIdAndUpdate(userId, {
      selectedGoal,
      onboardingStep: 2,
    })
  },

  // ── Step 2 — Select habit categories → create Habit docs ─────────
  selectHabits: async (userId, categories) => {
    // Delete any previously created onboarding habits (idempotent)
    await Habit.deleteMany({ userId, isActive: true })

    const habits = []

    for (const category of categories) {
      const template = HABIT_TEMPLATES.find((t) => t.category === category)
      if (!template) continue

      const habit = await Habit.create({
        userId,
        name:     template.name,
        category: template.category,
        icon:     template.icon,
        color:    template.color,
        startDate: new Date().toISOString().split('T')[0],
        isCustom: category === 'custom',
        displayOrder: habits.length,
      })

      // Create default subtasks for this habit
      const subtaskDocs = await Subtask.insertMany(
        template.subtasks.map((st, i) => ({
          habitId:      habit._id,
          userId,
          name:         st.name,
          inputType:    st.inputType || 'checkbox',
          unit:         st.unit || null,
          targetValue:  st.targetValue || null,
          isRequired:   st.isRequired !== false,
          displayOrder: st.displayOrder ?? i,
        }))
      )

      habits.push({
        ...habit.toObject(),
        subtasks: subtaskDocs,
      })
    }

    await User.findByIdAndUpdate(userId, { onboardingStep: 3 })
    return habits
  },

  // ── Step 3 — Configure which subtasks are enabled ─────────────────
  // habitSubtasks: [{ habitId, enabledSubtaskIds?, customSubtasks? }]
  configureSubtasks: async (userId, habitSubtasks) => {
    for (const config of habitSubtasks) {
      const { habitId, enabledSubtaskIds, customSubtasks } = config

      // Verify ownership
      const habit = await Habit.findOne({ _id: habitId, userId })
      if (!habit) continue

      // Disable subtasks not in enabledSubtaskIds
      if (enabledSubtaskIds && enabledSubtaskIds.length > 0) {
        const allSubtasks = await Subtask.find({ habitId, userId })

        for (const subtask of allSubtasks) {
          const shouldBeActive = enabledSubtaskIds.includes(subtask._id.toString())
          if (subtask.isActive !== shouldBeActive) {
            await Subtask.findByIdAndUpdate(subtask._id, {
              isActive: shouldBeActive,
            })
          }
        }
      }

      // Add custom subtasks
      if (customSubtasks && customSubtasks.length > 0) {
        const existingCount = await Subtask.countDocuments({
          habitId, userId, isActive: true,
        })

        await Subtask.insertMany(
          customSubtasks.map((st, i) => ({
            habitId,
            userId,
            name:         st.name,
            inputType:    st.inputType || 'checkbox',
            unit:         st.unit || null,
            targetValue:  st.targetValue || null,
            isRequired:   st.isRequired !== false,
            displayOrder: existingCount + i,
          }))
        )
      }
    }

    await User.findByIdAndUpdate(userId, { onboardingStep: 4 })
  },

  // ── Step 4 — Set reminders per habit ────────────────────────────
  // reminders: [{ habitId, times: ['08:00'], days: [0,1,2,3,4,5,6] }]
  setReminders: async (userId, reminders) => {
    if (!reminders || reminders.length === 0) {
      await User.findByIdAndUpdate(userId, { onboardingStep: 5 })
      return
    }

    for (const reminder of reminders) {
      const { habitId, times, days } = reminder

      await Habit.findOneAndUpdate(
        { _id: habitId, userId },
        {
          reminderEnabled: true,
          reminderTimes:   times || [],
          reminderDays:    days  || [0, 1, 2, 3, 4, 5, 6],
        }
      )
    }

    await User.findByIdAndUpdate(userId, { onboardingStep: 5 })
  },

  // ── Step 5 — Mark onboarding complete ────────────────────────────
  complete: async (userId) => {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        onboardingCompleted: true,
        onboardingStep:      5,
      },
      { new: true }
    ).select('name username email level xpPoints currentStreakDays')

    if (!user) throwNotFound('User')

    const habits = await Habit.find({ userId, isActive: true })
      .populate('subtasks')
      .lean()

    return { user, habits }
  },
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
const throwNotFound = (entity) => {
  const err = new Error(`${entity} not found`)
  err.statusCode = 404
  throw err
}