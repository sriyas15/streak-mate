import { freezeService } from '../services/freeze.service.js'

export const freezeController = {
  // GET /freeze/balance
  getBalance: async (req, reply) => {
    const balance = await freezeService.getBalance(req.user._id)
    return reply.send({ success: true, data: { balance } })
  },

  // POST /freeze/activate  body: { date, reason? }
  activateFreeze: async (req, reply) => {
    const { date, reason } = req.body
    const result = await freezeService.activateFreeze(req.user._id, { date, reason })
    return reply.send({
      success: true,
      message: 'Streak freeze activated ❄️',
      data: result,
    })
  },

  // POST /freeze/cheat-day/activate  body: { date }
  activateCheatDay: async (req, reply) => {
    const { date } = req.body
    const result = await freezeService.activateCheatDay(req.user._id, date)
    return reply.send({
      success: true,
      message: "Cheat day used. Don't make it a habit 😏",
      data: result,
    })
  },

  // GET /freeze/history
  getHistory: async (req, reply) => {
    const history = await freezeService.getHistory(req.user._id)
    return reply.send({ success: true, data: { history } })
  },
}