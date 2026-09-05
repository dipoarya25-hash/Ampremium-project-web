import { createClient } from '@supabase/supabase-js'

const usernamePattern = /^[a-z0-9][a-z0-9_.-]{2,31}$/
const emailFor = (username) => `${username}@users.amprem.local`
const usernameOf = (value) => String(value || '').trim().toLowerCase()
const cookie = (header = '') => Object.fromEntries(header.split(';').map((p) => {
  const i = p.indexOf('=')
  return i < 0 ? [] : [p.slice(0, i).trim(), decodeURIComponent(p.slice(i + 1).trim())]
}).filter((p) => p.length))

export function mountAuth(app, publicDir) {
  const { SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: key, SUPABASE_SERVICE_ROLE_KEY: service } = process.env
  if (!url || !key || !service) throw new Error('SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, dan SUPABASE_SERVICE_ROLE_KEY wajib diisi di .env')
  const auth = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
  const admin = createClient(url, service, { auth: { persistSession: false, autoRefreshToken: false } })
  const deny = (req, res) => req.path.startsWith('/api/') ? res.status(401).json({ ok: false, message: 'Silakan login sebagai pengguna.' }) : res.redirect('/login')

  async function lookupUsername(username) {
    for (let page = 1; page <= 20; page++) {
      const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 })
      if (error) throw error
      const user = data.users.find((item) => item.user_metadata?.username === username || item.email === emailFor(username) || item.email?.split('@')[0] === username)
      if (user || data.users.length < 1000) return user || null
    }
    return null
  }
  async function loggedIn(req, res, next) {
    const token = cookie(req.headers.cookie).amprem_session
    if (!token) return deny(req, res)
    const { data, error } = await auth.auth.getUser(token)
    if (error || !data.user || data.user.app_metadata?.role === 'admin') return deny(req, res)
    req.user = data.user
    next()
  }

  app.get('/login', (_req, res) => res.sendFile(`${publicDir}/login.html`))
  app.post('/api/auth/login', async (req, res) => {
    const username = usernameOf(req.body?.username), password = String(req.body?.password || '')
    if (!usernamePattern.test(username) || !password) return res.status(400).json({ ok: false, message: 'Username atau password tidak valid.' })
    try {
      const user = await lookupUsername(username)
      if (!user?.email) return res.status(401).json({ ok: false, message: 'Username atau password salah.' })
      const { data, error } = await auth.auth.signInWithPassword({ email: user.email, password })
      if (error || !data.session || !data.user) return res.status(401).json({ ok: false, message: 'Username atau password salah.' })
      if (data.user.app_metadata?.role === 'admin') return res.status(403).json({ ok: false, message: 'Gunakan website admin untuk masuk.' })
      const secure = process.env.NODE_ENV === 'production' ? '; Secure' : ''
      res.setHeader('Set-Cookie', `amprem_session=${encodeURIComponent(data.session.access_token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=3600${secure}`)
      res.json({ ok: true })
    } catch (error) { res.status(500).json({ ok: false, message: `Login gagal: ${error.message}` }) }
  })
  app.post('/api/auth/logout', (_req, res) => { res.setHeader('Set-Cookie', 'amprem_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0'); res.json({ ok: true }) })
  app.use(loggedIn)
  app.get('/api/auth/me', (req, res) => res.json({ ok: true, user: { username: req.user.user_metadata?.username, isAdmin: false } }))
  app.post('/api/history/sync', async (req, res) => {
    const rawHistory = Array.isArray(req.body?.history) ? req.body.history : []
    const history = rawHistory.slice(0, 30).map((item) => ({
      orderId: String(item?.orderId || '').slice(0, 80),
      email: String(item?.email || '').slice(0, 254),
      duration: String(item?.duration || '').slice(0, 80),
      createdAt: String(item?.createdAt || '').slice(0, 40),
      status: String(item?.status || '').slice(0, 40)
    })).filter((item) => item.orderId && item.email && !Number.isNaN(new Date(item.createdAt).getTime()))
    try {
      const { error } = await admin.auth.admin.updateUserById(req.user.id, {
        user_metadata: { ...req.user.user_metadata, amprem_history: history }
      })
      if (error) throw error
      res.json({ ok: true, count: history.length })
    } catch (error) {
      res.status(500).json({ ok: false, message: `Gagal menyinkronkan riwayat: ${error.message}` })
    }
  })
}
