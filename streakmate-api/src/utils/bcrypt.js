import bcrypt from 'bcrypt'
import { env } from '../config/env.js'

export const hashPassword = async (password) => {
  return bcrypt.hash(password, env.BCRYPT_SALT_ROUNDS)
}

export const comparePassword = async (plain, hashed) => {
  return bcrypt.compare(plain, hashed)
}