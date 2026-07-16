import { Habit, Subtask, HabitLog, User } from '../models/index.js'
import { deleteCache, deletePattern, CACHE_KEYS } from '../config/redis.js'
import { getTodayDate, getTodayDayOfWeek } from '../utils/dateHelper.js'
import { HABIT_TEMPLATES } from '../utils/constants.js'

export const habitService = {
  // ── Get all habits ───────────────────────────────────────────────
  getAllHabits: async (userId, query = {}) => {
    const filter = { userId, isActive: true }
    if (query.archived === 'true') filter.isArchived = true
    else filter.isArchived = false

    if (query.category) filter.category = query.category

    return Habit.find(filter).sort({ displayOrder: 1, createdAt: 1 }).lean()
  },

  // ── Create habit ────────────────────────────────────────────────
createHabit: async (userId, body) => {
  const count = await Habit.countDocuments({ userId, isActive: true, isArchived: false })
  if (count >= 10) throwBadRequest('Maximum 10 active habits allowed')

  const existing = await Habit.findOne({
    userId, category: body.category, name: body.name,
    isActive: true, isArchived: false,
  })
  if (existing) throwBadRequest(`You already have a "${body.name}" habit`)

  const habit = await Habit.create({
    userId,
    name: body.name,
    category: body.category,
    icon: body.icon,
    color: body.color,
    description: body.description,
    frequency: body.frequency || 'daily',
    activeDays: body.activeDays || [0, 1, 2, 3, 4, 5, 6],
    startDate: body.startDate || getTodayDate(),
    completionRule: body.completionRule || 'all_required',
    completionThreshold: body.completionThreshold || 100,
    reminderEnabled: body.reminderEnabled || false,
    reminderTimes: body.reminderTimes || [],
    isCustom: body.category === 'custom',
    displayOrder: count,
  })

  // Template subtasks
  const template = HABIT_TEMPLATES.find((t) => t.category === body.category)
  let subtaskDocs = []
  if (template && template.subtasks?.length > 0) {
    subtaskDocs = await Subtask.insertMany(
      template.subtasks.map((st, i) => ({
        habitId: habit._id,
        userId,
        name: st.name,
        inputType: st.inputType || 'checkbox',
        unit: st.unit || null,
        targetValue: st.targetValue || null,
        isRequired: st.isRequired !== false,
        displayOrder: st.displayOrder ?? i,
      }))
    )
  }

  // ── NEW: user's custom subtasks (plain strings from the UI) ────
  if (body.customSubtasks && body.customSubtasks.length > 0) {
    const customDocs = await Subtask.insertMany(
      body.customSubtasks.map((name, i) => ({
        habitId: habit._id,
        userId,
        name,
        inputType: 'checkbox',
        isRequired: true,
        displayOrder: subtaskDocs.length + i,
      }))
    )
    subtaskDocs = [...subtaskDocs, ...customDocs]
  }

  await deletePattern(`user:${userId}:today:*`)

  return {
    ...habit.toObject(),
    subtasks: subtaskDocs,
  }
},

  // ── Get single habit ─────────────────────────────────────────────
  getHabit: async (userId, habitId) => {
    const habit = await Habit.findOne({ _id: habitId, userId }).lean()
    if (!habit) throwNotFound('Habit')
    return habit
  },

  // ── Update habit ────────────────────────────────────────────────
  updateHabit: async (userId, habitId, updates) => {
    const allowed = [
      'name', 'icon', 'color', 'description',
      'frequency', 'activeDays', 'endDate',
      'reminderEnabled', 'reminderTimes', 'reminderDays',
    ]
    const filtered = {}
    for (const key of allowed) {
      if (updates[key] !== undefined) filtered[key] = updates[key]
    }

    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      filtered,
      { new: true, runValidators: true }
    )
    if (!habit) throwNotFound('Habit')

    await deletePattern(`user:${userId}:today:*`)
    return habit
  },

  // ── Delete habit ────────────────────────────────────────────────
  deleteHabit: async (userId, habitId) => {
    const habit = await Habit.findOneAndDelete({ _id: habitId, userId })
    if (!habit) throwNotFound('Habit')

    // Clean up subtasks + logs
    await Subtask.deleteMany({ habitId })
    await HabitLog.deleteMany({ habitId, userId })

    await deletePattern(`user:${userId}:today:*`)
    await deleteCache(CACHE_KEYS.habitStreak(userId, habitId))
  },

  // ── Archive habit ────────────────────────────────────────────────
  archiveHabit: async (userId, habitId) => {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { isArchived: true },
      { new: true }
    )
    if (!habit) throwNotFound('Habit')
    await deletePattern(`user:${userId}:today:*`)
  },

  // ── Restore habit ────────────────────────────────────────────────
  restoreHabit: async (userId, habitId) => {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { isArchived: false },
      { new: true }
    )
    if (!habit) throwNotFound('Habit')
    await deletePattern(`user:${userId}:today:*`)
  },

  // ── Reorder habit ────────────────────────────────────────────────
  reorderHabit: async (userId, habitId, displayOrder) => {
    await Habit.findOneAndUpdate({ _id: habitId, userId }, { displayOrder })
    await deletePattern(`user:${userId}:today:*`)
  },

  // ── Update completion rule ───────────────────────────────────────
  updateCompletionRule: async (userId, habitId, { completionRule, completionThreshold }) => {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { completionRule, completionThreshold },
      { new: true }
    )
    if (!habit) throwNotFound('Habit')
    return habit
  },

  // ── Get all templates ────────────────────────────────────────────
  getTemplates: async () => HABIT_TEMPLATES,

  // ── Get templates by category ─────────────────────────────────────
  getTemplatesByCategory: async (category) => {
    const template = HABIT_TEMPLATES.find((t) => t.category === category)
    if (!template) throwNotFound('Template')
    return template
  },

  // ── Get today's habits with log status ───────────────────────────
  getTodayHabits: async (userId) => {
    const user = await User.findById(userId)
    const today = getTodayDate(user.timezone)
    const dayOfWeek = getTodayDayOfWeek(user.timezone)

    const habits = await Habit.find({
      userId,
      isActive: true,
      isArchived: false,
      activeDays: dayOfWeek,
    }).sort({ displayOrder: 1 }).lean()

    // Attach today's log to each habit
    const habitIds = habits.map((h) => h._id)
    const logs = await HabitLog.find({ userId, date: today, habitId: { $in: habitIds } }).lean()

    const logMap = {}
    for (const log of logs) {
      logMap[log.habitId.toString()] = log
    }

    return habits.map((habit) => ({
      ...habit,
      todayLog: logMap[habit._id.toString()] || null,
    }))
  },
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