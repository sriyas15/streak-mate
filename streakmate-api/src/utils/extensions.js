/**
 * extensions.js
 * Small general-purpose helpers used across the codebase
 */

// ─── Capitalize first letter ──────────────────────────────────────────────────
export const capitalize = (str) =>
  str ? str.charAt(0).toUpperCase() + str.slice(1) : ''

// ─── Safe JSON parse ──────────────────────────────────────────────────────────
export const safeJsonParse = (str, fallback = null) => {
  try {
    return JSON.parse(str)
  } catch {
    return fallback
  }
}

// ─── Remove undefined/null keys from object ──────────────────────────────────
export const cleanObject = (obj) => {
  const cleaned = {}
  for (const [key, value] of Object.entries(obj)) {
    if (value !== undefined && value !== null) cleaned[key] = value
  }
  return cleaned
}

// ─── Pick only allowed keys from an object ───────────────────────────────────
export const pickKeys = (obj, keys) => {
  const result = {}
  for (const key of keys) {
    if (key in obj) result[key] = obj[key]
  }
  return result
}

// ─── Chunk an array into batches ─────────────────────────────────────────────
export const chunkArray = (arr, size) => {
  const chunks = []
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size))
  }
  return chunks
}

// ─── Sleep (async delay) ──────────────────────────────────────────────────────
export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

// ─── Generate a random integer between min and max (inclusive) ───────────────
export const randomInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min

// ─── Deduplicate an array by a key ───────────────────────────────────────────
export const dedupeBy = (arr, key) => {
  const seen = new Set()
  return arr.filter((item) => {
    const val = item[key]
    if (seen.has(val)) return false
    seen.add(val)
    return true
  })
}

// ─── Convert MongoDB ObjectId array to string array ──────────────────────────
export const toStringArray = (arr) => arr.map((id) => id.toString())

// ─── Check if a string is a valid MongoDB ObjectId ───────────────────────────
export const isValidObjectId = (str) => /^[a-f\d]{24}$/i.test(str)

// ─── Pluralize a word ─────────────────────────────────────────────────────────
export const pluralize = (count, singular, plural) =>
  count === 1 ? singular : (plural || singular + 's')

// ─── Mask email for display (ri****@gmail.com) ────────────────────────────────
export const maskEmail = (email) => {
  const [local, domain] = email.split('@')
  const masked = local.slice(0, 2) + '****'
  return `${masked}@${domain}`
}