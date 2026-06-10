import admin from 'firebase-admin'
import { env } from './env.js'

let firebaseApp = null

// ─── Initialize Firebase Admin SDK ──────────────────────────────────────────
export const initFCM = () => {
  if (admin.apps.length > 0) {
    firebaseApp = admin.app()
    return firebaseApp
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      // private key comes as escaped string from env — unescape newlines
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  })

  console.log('✅ Firebase Admin SDK initialized')
  return firebaseApp
}

// ─── Send to single device ───────────────────────────────────────────────────
export const sendPushNotification = async ({ token, title, body, data = {}, imageUrl = null }) => {
  const message = {
    token,
    notification: {
      title,
      body,
      ...(imageUrl && { imageUrl }),
    },
    data: serializeData(data), // FCM data must be all strings
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  }

  try {
    const response = await admin.messaging().send(message)
    return { success: true, messageId: response }
  } catch (err) {
    // Token no longer valid — caller should deactivate it
    if (
      err.code === 'messaging/registration-token-not-registered' ||
      err.code === 'messaging/invalid-registration-token'
    ) {
      return { success: false, invalidToken: true, error: err.message }
    }
    return { success: false, invalidToken: false, error: err.message }
  }
}

// ─── Send to multiple devices (batch) ───────────────────────────────────────
export const sendMulticastNotification = async ({ tokens, title, body, data = {}, imageUrl = null }) => {
  if (!tokens || tokens.length === 0) return { success: false, error: 'No tokens provided' }

  const message = {
    tokens,
    notification: {
      title,
      body,
      ...(imageUrl && { imageUrl }),
    },
    data: serializeData(data),
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    },
  }

  try {
    const response = await admin.messaging().sendEachForMulticast(message)
    const invalidTokens = []

    response.responses.forEach((res, i) => {
      if (!res.success) {
        const code = res.error?.code
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          invalidTokens.push(tokens[i])
        }
      }
    })

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokens, // caller should deactivate these
    }
  } catch (err) {
    return { success: false, error: err.message }
  }
}

// ─── Send to a topic (e.g. "all-users" for global announcements) ─────────────
export const sendToTopic = async ({ topic, title, body, data = {} }) => {
  const message = {
    topic,
    notification: { title, body },
    data: serializeData(data),
  }

  try {
    const response = await admin.messaging().send(message)
    return { success: true, messageId: response }
  } catch (err) {
    return { success: false, error: err.message }
  }
}

// ─── Subscribe tokens to topic ───────────────────────────────────────────────
export const subscribeToTopic = async (tokens, topic) => {
  try {
    await admin.messaging().subscribeToTopic(tokens, topic)
    return { success: true }
  } catch (err) {
    return { success: false, error: err.message }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

// FCM requires all data values to be strings
const serializeData = (data) => {
  const result = {}
  for (const [key, value] of Object.entries(data)) {
    result[key] = String(value)
  }
  return result
}