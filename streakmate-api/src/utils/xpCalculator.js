/**
 * xpCalculator.js
 * Pure XP and level calculation functions
 * Used by gamification.service.js and tests
 */

// ─── XP thresholds — total XP needed to reach each level ─────────────────────
export const XP_TABLE = [
  0,      // Level 1
  100,    // Level 2
  250,    // Level 3
  450,    // Level 4
  700,    // Level 5
  1000,   // Level 6
  1400,   // Level 7
  1900,   // Level 8
  2500,   // Level 9
  3200,   // Level 10
  4000,   // Level 11
  5000,   // Level 12
  6200,   // Level 13
  7600,   // Level 14
  9200,   // Level 15
  11000,  // Level 16
  13000,  // Level 17
  15500,  // Level 18
  18500,  // Level 19
  22000,  // Level 20 (max)
]

// ─── XP reward values ─────────────────────────────────────────────────────────
export const XP_REWARDS = {
  productive_day:     50,
  habit_complete:     10,
  streak_3:           30,
  streak_7:           100,
  streak_14:          150,
  streak_21:          200,
  streak_30:          300,
  streak_50:          500,
  streak_100:         1000,
  streak_365:         5000,
  perfect_week:       200,
  perfect_month:      500,
  first_habit:        50,
  friend_added:       20,
  nudge_sent:         5,
  achievement_base:   50,
}

// ─── Calculate level from total XP ───────────────────────────────────────────
export const calcLevel = (totalXP) => {
  let level = 1
  for (let i = 0; i < XP_TABLE.length; i++) {
    if (totalXP >= XP_TABLE[i]) level = i + 1
    else break
  }
  return Math.min(level, XP_TABLE.length)
}

// ─── Get XP threshold for a level ────────────────────────────────────────────
export const getThresholdForLevel = (level) => {
  return XP_TABLE[Math.min(level - 1, XP_TABLE.length - 1)] || 0
}

// ─── Get XP needed to reach next level ───────────────────────────────────────
export const getXPToNextLevel = (totalXP) => {
  const currentLevel = calcLevel(totalXP)
  if (currentLevel >= XP_TABLE.length) return 0 // max level

  const nextThreshold = XP_TABLE[currentLevel]
  return Math.max(0, nextThreshold - totalXP)
}

// ─── Get progress % within current level ──────────────────────────────────────
export const getLevelProgress = (totalXP) => {
  const currentLevel = calcLevel(totalXP)
  if (currentLevel >= XP_TABLE.length) return 100

  const currentThreshold = XP_TABLE[currentLevel - 1]
  const nextThreshold = XP_TABLE[currentLevel]
  const range = nextThreshold - currentThreshold
  const progress = totalXP - currentThreshold

  return Math.round((progress / range) * 100)
}

// ─── Build full level info object ────────────────────────────────────────────
export const buildLevelInfo = (totalXP) => {
  const level = calcLevel(totalXP)
  const isMaxLevel = level >= XP_TABLE.length
  const currentThreshold = XP_TABLE[level - 1] || 0
  const nextThreshold = isMaxLevel ? XP_TABLE[XP_TABLE.length - 1] : XP_TABLE[level]

  return {
    level,
    totalXP,
    isMaxLevel,
    xpInCurrentLevel: totalXP - currentThreshold,
    xpNeededForNextLevel: isMaxLevel ? 0 : nextThreshold - currentThreshold,
    xpToNextLevel: getXPToNextLevel(totalXP),
    progressPercent: getLevelProgress(totalXP),
    nextLevelThreshold: nextThreshold,
  }
}

// ─── Check if XP award triggers a level up ────────────────────────────────────
export const checkLevelUp = (oldXP, newXP) => {
  const oldLevel = calcLevel(oldXP)
  const newLevel = calcLevel(newXP)
  return {
    leveledUp: newLevel > oldLevel,
    oldLevel,
    newLevel,
  }
}