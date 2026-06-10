import { authRoutes } from './auth.routes.js'
import { userRoutes } from './user.routes.js'
import { habitRoutes } from './habit.routes.js'
import { subtaskRoutes } from './subtask.routes.js'
import { habitLogRoutes } from './habitLog.routes.js'
import { dayLogRoutes } from './dayLog.routes.js'
import { streakRoutes } from './streak.routes.js'
import { analyticsRoutes } from './analytics.routes.js'
import { calendarRoutes } from './calendar.routes.js'
import { freezeRoutes } from './freeze.routes.js'
import { notificationRoutes } from './notification.routes.js'
import { friendsRoutes } from './friends.routes.js'
import { leaderboardRoutes } from './leaderboard.routes.js'
import { achievementRoutes } from './achievement.routes.js'
import { gamificationRoutes } from './gamification.routes.js'
import { onboardingRoutes } from './onboarding.routes.js'
import { appConfigRoutes } from './appConfig.routes.js'

export const registerRoutes = async (fastify) => {
    fastify.register(authRoutes, { prefix: '/auth' })
    fastify.register(userRoutes, { prefix: '/users' })
    fastify.register(habitRoutes, { prefix: '/habits' })
    fastify.register(subtaskRoutes, { prefix: '/habits' })      // /habits/:habitId/subtasks
    fastify.register(habitLogRoutes, { prefix: '/habits' })      // /habits/:habitId/logs
    fastify.register(dayLogRoutes, { prefix: '/daylogs' })
    fastify.register(streakRoutes, { prefix: '/streaks' })
    fastify.register(analyticsRoutes, { prefix: '/analytics' })
    fastify.register(calendarRoutes, { prefix: '/calendar' })
    fastify.register(freezeRoutes, { prefix: '/freeze' })
    fastify.register(notificationRoutes, { prefix: '/notifications' })
    fastify.register(friendsRoutes, { prefix: '/friends' })
    fastify.register(leaderboardRoutes, { prefix: '/leaderboard' })
    fastify.register(achievementRoutes, { prefix: '/achievements' })
    fastify.register(gamificationRoutes, { prefix: '/gamification' })
    fastify.register(onboardingRoutes, { prefix: '/onboarding' })
    fastify.register(appConfigRoutes, { prefix: '/config' })
}