import buildApp from './src/app.js'
import {connectDB} from './src/config/db.js'
import { env } from './src/config/env.js'
import { initSocket } from './src/socket/index.js'
import {registerScheduledJobs} from './src/services/jobScheduler.service.js'
import dns from 'dns';
dns.setServers(['8.8.8.8', '1.1.1.1']);

const startServer = async () => {
  try {
    // Connect MongoDB
    await connectDB()

    // Create Fastify instance
    const app = await buildApp()

    // Start server
    await app.listen({
      port: env.PORT,
      host: '0.0.0.0',
    })
    await registerScheduledJobs()

    initSocket(app.server)

    console.log(`🚀 Server running on http://localhost:${env.PORT}`)
  } catch (error) {
    console.error('❌ Failed to start server:', error)
    process.exit(1)
  }
}

startServer()