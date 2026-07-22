import mongoose from 'mongoose'
import dns from 'dns'
dns.setServers(['8.8.8.8', '1.1.1.1'])
import { env } from '../config/env.js'
import { connectDB } from '../config/db.js'
import { Achievement } from '../models/index.js'

const achievements = [
  { name: 'First Step', description: 'Complete your first habit', icon: '👣', condition: 'first_habit_complete', xpReward: 50, isActive: true, displayOrder: 0, type: 'completion' },
  { name: '3-Day Streak', description: 'Maintain a 3-day streak', icon: '🔥', condition: 'streak_3', conditionValue: 3, xpReward: 30, isActive: true, displayOrder: 1, type: 'streak' },
  { name: 'Week Warrior', description: 'Hit a 7-day streak', icon: '⚔️', condition: 'streak_7', conditionValue: 7, xpReward: 100, isActive: true, displayOrder: 2, type: 'streak' },
  { name: 'Fortnight Fighter', description: '14-day streak', icon: '🛡️', condition: 'streak_14', conditionValue: 14, xpReward: 150, isActive: true, displayOrder: 3, type: 'streak' },
  { name: 'Three Weeks Strong', description: '21-day streak', icon: '💪', condition: 'streak_21', conditionValue: 21, xpReward: 200, isActive: true, displayOrder: 4, type: 'streak' },
  { name: 'Month Master', description: '30-day streak', icon: '👑', condition: 'streak_30', conditionValue: 30, xpReward: 300, isActive: true, displayOrder: 5, type: 'streak' },
  { name: 'Half Century', description: '50-day streak', icon: '💎', condition: 'streak_50', conditionValue: 50, xpReward: 500, isActive: true, displayOrder: 6, type: 'streak' },
  { name: 'Century Club', description: '100-day streak', icon: '🚀', condition: 'streak_100', conditionValue: 100, xpReward: 1000, isActive: true, displayOrder: 7, type: 'streak' },
  { name: 'Perfect Week', description: 'All habits done every day for a week', icon: '✨', condition: 'perfect_week', xpReward: 200, isActive: true, displayOrder: 8, type: 'completion' },
  { name: 'Social Butterfly', description: 'Add 5 friends', icon: '🦋', condition: 'add_5_friends', xpReward: 100, isActive: true, displayOrder: 9, type: 'social' },
  { name: 'Motivator', description: 'Nudge a friend', icon: '👊', condition: 'nudge_sent', xpReward: 5, isActive: true, displayOrder: 10, type: 'social' },
  { name: 'Year of Wins', description: '365-day streak', icon: '🌟', condition: 'streak_365', conditionValue: 365, xpReward: 5000, isActive: true, displayOrder: 11, type: 'streak' },
]

const seed = async () => {
  try {
    await connectDB()
    console.log('🌱 Connected to database.')
    
    // Clear existing achievements to prevent duplicates
    await Achievement.deleteMany({})
    console.log('🗑️  Cleared existing achievements.')
    
    // Insert new achievements
    await Achievement.insertMany(achievements)
    console.log(`✅ Successfully seeded ${achievements.length} achievements.`)
    
    process.exit(0)
  } catch (error) {
    console.error('❌ Error seeding achievements:', error)
    process.exit(1)
  }
}

seed()
