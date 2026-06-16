import { AppConfig, NotificationTemplate } from '../models/index.js'
import { HABIT_TEMPLATES, APP_CONFIG_DEFAULTS } from '../utils/constants.js'

export const appConfigService = {
  // ── Get public app config ────────────────────────────────────────
  // Returns key-value pairs the Flutter app needs on startup
  // e.g. default_freezes, max_habits, xp_per_day etc.
  getAppConfig: async () => {
    const configs = await AppConfig.find({ isPublic: true }).lean()

    if (configs.length === 0) {
      // First boot — seed defaults and return them
      await appConfigService.seedDefaults()
      return APP_CONFIG_DEFAULTS.reduce((acc, item) => {
        acc[item.key] = item.value
        return acc
      }, {})
    }

    return configs.reduce((acc, item) => {
      acc[item.key] = item.value
      return acc
    }, {})
  },

  // ── Get all habit templates ───────────────────────────────────────
  // Returns the 6 category templates with their default subtasks
  // Flutter uses this to populate onboarding + add habit screen
  getHabitTemplates: async () => {
    return HABIT_TEMPLATES
  },

  // ── Get notification templates ────────────────────────────────────
  // Returns all active templates with bodyVariants for funny notifs
  getNotificationTemplates: async () => {
    const templates = await NotificationTemplate.find({ isActive: true })
      .select('type title bodyVariants variables platform')
      .lean()

    return templates
  },

  // ── Seed default app config ───────────────────────────────────────
  // Called on first boot if AppConfig collection is empty
  seedDefaults: async () => {
    const existing = await AppConfig.countDocuments()
    if (existing > 0) return

    await AppConfig.insertMany(
      APP_CONFIG_DEFAULTS.map((item) => ({
        key:         item.key,
        value:       item.value,
        description: item.description,
        isPublic:    true,
      }))
    )

    console.log('✅ AppConfig seeded with defaults')
  },

  // ── Get single config value by key ───────────────────────────────
  getValue: async (key) => {
    const config = await AppConfig.findOne({ key }).lean()
    return config?.value ?? null
  },

  // ── Update a config value (admin use) ────────────────────────────
  setValue: async (key, value) => {
    await AppConfig.findOneAndUpdate(
      { key },
      { value },
      { upsert: true, new: true }
    )
  },
}