/**
 * Website Alight Motion Premium - 7 varian, masing-masing halaman
 * TERPISAH (bukan 1 halaman dengan tab/switcher). Project ini BERDIRI
 * SENDIRI - gak ada hubungan atau dependency ke bot WhatsApp manapun.
 *
 * Jalanin: npm install && npm start
 * Bisa jalan di VPS, Pterodactyl (egg Node.js generic), Termux, dll -
 * cuma butuh Node.js >= 18.
 */

import express from 'express'
import path from 'path'
import os from 'os'
import { fileURLToPath } from 'url'
import { config } from './config.js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const app = express()
const PORT = process.env.PORT || process.env.SERVER_PORT || 3000

app.use(express.json())
app.use(express.static(path.join(__dirname, 'public')))

// ---------- Helper bersama ----------

async function postJSON(url, headers, body) {
  const res = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body), signal: AbortSignal.timeout(15000) })
  const raw = await res.text()
  try {
    return JSON.parse(raw)
  } catch {
    throw new Error(`Server balas bukan JSON (HTTP ${res.status}): ${raw.slice(0, 150)}`)
  }
}

function validEmail(email) {
  return typeof email === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function validLink(link) {
  try {
    const u = new URL(link)
    return /^https?:$/.test(u.protocol)
  } catch {
    return false
  }
}

async function tryEndpoints(urls) {
  const shuffled = [...urls].sort(() => Math.random() - 0.5)
  for (const url of shuffled) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(15000) })
      const data = await res.json().catch(() => null)
      if (!data) continue
      const isSuccess = data.status !== false && data.status !== 'error' && data.status !== 'failed'
      if (isSuccess) return data
    } catch {
      continue
    }
  }
  return null
}

// ---------- dapjimotionpro.my.id (amprem, amprem3, amprem4, amprem5) ----------
// Route-nya dikasih namespace per varian (/api/amprem/..., /api/amprem3/...,
// dst) walau backend aslinya sama - ini "solusi biar nggak ada yang tabrak":
// masing-masing varian punya jalur API sendiri yang gak overlap.

const DAPJI_PROXY_API = 'https://www.dapjimotionpro.my.id/api/proxy-amprem'
const dapjiHeaders = {
  'Content-Type': 'application/json',
  'User-Agent': 'Mozilla/5.0 (Android 10; Mobile; rv:154.0) Gecko/154.0 Firefox/154.0',
  Referer: 'https://www.dapjimotionpro.my.id/generator-v2'
}

function registerDapjiRoutes(prefix) {
  app.post(`/api/${prefix}/send`, async (req, res) => {
    const email = (req.body?.email || '').trim()
    if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })
    try {
      const result = await postJSON(DAPJI_PROXY_API, dapjiHeaders, { action: 'send', email })
      if (!result.success) return res.status(502).json({ ok: false, message: result.message || 'Gagal mengirim link' })
      return res.json({ ok: true, message: result.message || 'Link verifikasi terkirim', email })
    } catch (err) {
      return res.status(500).json({ ok: false, message: err.message })
    }
  })

  app.post(`/api/${prefix}/verify`, async (req, res) => {
    const email = (req.body?.email || '').trim()
    const link = (req.body?.link || '').trim()
    if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })
    if (!validLink(link)) return res.status(400).json({ ok: false, message: 'Link tidak valid' })
    try {
      const result = await postJSON(DAPJI_PROXY_API, dapjiHeaders, { action: 'verify', email, link })
      if (!result.success) return res.status(502).json({ ok: false, message: result.message || 'Verifikasi gagal' })
      return res.json({ ok: true, message: result.message || 'Verifikasi berhasil', email })
    } catch (err) {
      return res.status(500).json({ ok: false, message: err.message })
    }
  })
}

registerDapjiRoutes('amprem')
registerDapjiRoutes('amprem3')
registerDapjiRoutes('amprem4')
registerDapjiRoutes('amprem5')

// ---------- haidarxd.my.id (amprem2 - sekali panggil, gak perlu email) ----------

app.post('/api/amprem2/generate', async (_req, res) => {
  try {
    const apikey = config.amprem2ApiKey
    const qs = apikey ? `?apikey=${encodeURIComponent(apikey)}` : ''
    const apiUrl = `https://api.haidarxd.my.id/api/v1/alight-motion/auto${qs}`
    const apiRes = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
      signal: AbortSignal.timeout(15000)
    })
    const raw = await apiRes.text()
    let data
    try {
      data = JSON.parse(raw)
    } catch {
      return res.status(502).json({ ok: false, message: `Server balas bukan JSON (HTTP ${apiRes.status})`, raw: raw.slice(0, 300) })
    }
    if (data.status === 'error' || data.error) {
      return res.status(502).json({ ok: false, message: data.error?.message || data.message || 'API mengembalikan error', data })
    }
    return res.json({ ok: true, data })
  } catch (err) {
    return res.status(500).json({ ok: false, message: err.message })
  }
})

// ---------- free-restapi.biz.id (amprem6, 3 endpoint fallback) ----------

app.post('/api/amprem6/send', async (req, res) => {
  const email = (req.body?.email || '').trim()
  if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })

  try {
    const apikey = config.amprem6ApiKey
    const urls = [
      `https://free-restapi.biz.id/api/alightmotion-send?email=${encodeURIComponent(email)}&apikey=${apikey}`,
      `https://www.free-restapi.biz.id/api/alight-senid?email=${encodeURIComponent(email)}&apikey=${apikey}`,
      `https://www.free-restapi.biz.id/api/am-send?email=${encodeURIComponent(email)}&apikey=${apikey}`
    ]
    const result = await tryEndpoints(urls)
    if (!result) {
      return res.status(502).json({
        ok: false,
        message: 'Gagal mengirim link. API key komunitas mungkin lagi limit - daftar sendiri di free-restapi.biz.id/users/register'
      })
    }
    return res.json({ ok: true, email: result.data?.email || email })
  } catch (err) {
    return res.status(500).json({ ok: false, message: err.message })
  }
})

app.post('/api/amprem6/verify', async (req, res) => {
  const email = (req.body?.email || '').trim()
  const link = (req.body?.link || '').trim()
  if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })
  if (!validLink(link)) return res.status(400).json({ ok: false, message: 'Link tidak valid' })

  try {
    const apikey = config.amprem6ApiKey
    const urls = [
      `https://free-restapi.biz.id/api/alightmotion-verify?email=${encodeURIComponent(email)}&link=${encodeURIComponent(link)}&apikey=${apikey}`,
      `https://www.free-restapi.biz.id/api/alight-verifyy?email=${encodeURIComponent(email)}&magicLink=${encodeURIComponent(link)}&apikey=${apikey}`,
      `https://www.free-restapi.biz.id/api/am-verify?email=${encodeURIComponent(email)}&link=${encodeURIComponent(link)}&apikey=${apikey}`
    ]
    const result = await tryEndpoints(urls)
    if (!result) return res.status(502).json({ ok: false, message: 'Verifikasi gagal, pastikan link benar' })
    return res.json({ ok: true, email: result.data?.email || email, duration: result.data?.duration || '1 Tahun' })
  } catch (err) {
    return res.status(500).json({ ok: false, message: err.message })
  }
})

// ---------- api.theresav.eu (amprem7) ----------
// Beda dari yang lain: API-nya dipanggil via GET + query string
// (bukan POST JSON), jadi helper-nya beda sendiri.
// BUTUH API KEY - isi di config.js

async function getJSON(url) {
  const res = await fetch(url, { signal: AbortSignal.timeout(15000) })
  const raw = await res.text()
  try {
    return { httpStatus: res.status, data: JSON.parse(raw) }
  } catch {
    throw new Error(`Server balas bukan JSON (HTTP ${res.status}): ${raw.slice(0, 150)}`)
  }
}

function isApiFailure(data) {
  return data.status === false || data.status === 'error' || data.success === false
}

// ---------- temp-email14 RapidAPI (Inbox Mail) ----------
// API key sengaja hanya ada di config.js + server. Browser cukup menerima
// alamat dan mengirim access token mailbox-nya saat meminta daftar email.
const TEMP_EMAIL_API = 'https://temp-email14.p.rapidapi.com'

async function tempEmailRequest(path, accessToken) {
  const apikey = config.tempEmailRapidApiKey
  if (!apikey) throw new Error('API key Inbox Mail belum diset di config.js')
  const headers = {
    'x-rapidapi-key': apikey,
    'x-rapidapi-host': 'temp-email14.p.rapidapi.com',
    'Content-Type': 'application/json'
  }
  if (accessToken) headers.Authorization = accessToken
  const response = await fetch(`${TEMP_EMAIL_API}${path}`, { headers, signal: AbortSignal.timeout(15000) })
  const raw = await response.text()
  let data
  try { data = JSON.parse(raw) } catch { throw new Error(`Inbox API membalas format tidak dikenal (HTTP ${response.status})`) }
  if (!response.ok || data.success === false || data.status === false) throw new Error(data.msg || data.message || 'Inbox API gagal dipanggil')
  return data
}

// Provider mengubah nama field detail email di beberapa respons (misalnya
// body_html, message_text, atau payload.content). Cari nilai yang relevan
// secara rekursif agar tampilan Inbox tetap bisa membaca semuanya.
function findMailValue(source, names) {
  const queue = [source]
  const seen = new Set()
  while (queue.length) {
    const current = queue.shift()
    if (!current || typeof current !== 'object' || seen.has(current)) continue
    seen.add(current)
    for (const [key, value] of Object.entries(current)) {
      // Cocokkan persis. Jangan memakai includes(), karena message_id bisa
      // keliru dianggap sebagai isi dari field message.
      if (typeof value === 'string' && value.trim() && names.includes(key.toLowerCase())) return value
    }
    for (const value of Object.values(current)) if (value && typeof value === 'object') queue.push(value)
  }
  return ''
}

function extractSafeLinks(...values) {
  const matches = values.flatMap((value) => String(value || '').match(/https?:\/\/[^\s"'<>]+/g) || [])
  return [...new Set(matches.map((url) => url.replace(/[),.;]+$/, '')).filter((url) => {
    try { return ['http:', 'https:'].includes(new URL(url).protocol) } catch { return false }
  }))].slice(0, 12)
}

app.post('/api/inbox/new', async (_req, res) => {
  try {
    const data = await tempEmailRequest('/newmail')
    const mailbox = data.newmail
    if (!mailbox?.email || !mailbox?.access_token) throw new Error('Inbox API tidak mengembalikan mailbox')
    return res.json({ ok: true, email: mailbox.email, accessToken: mailbox.access_token })
  } catch (err) {
    return res.status(502).json({ ok: false, message: err.message })
  }
})

app.post('/api/inbox/preview', async (req, res) => {
  const accessToken = (req.body?.accessToken || '').trim()
  if (!/^[a-zA-Z0-9_-]{16,200}$/.test(accessToken)) return res.status(400).json({ ok: false, message: 'Token mailbox tidak valid' })
  try {
    // /mails adalah daftar mailbox lengkap; /preview/mails hanya ringkasan
    // subjek dan pada beberapa mailbox tidak langsung mencantumkan pesan baru.
    const data = await tempEmailRequest('/mails', accessToken)
    const mailTokens = Array.isArray(data.mails) ? data.mails : []
    // Endpoint /mails hanya mengembalikan token seperti "3MxwKb...".
    // Ambil detail tiap token agar UI menampilkan email yang bisa dibaca.
    const mails = await Promise.all(mailTokens.slice(0, 20).map(async (entry) => {
      const token = typeof entry === 'string' ? entry : entry?.token || entry?.id || entry?.mail_token
      if (!token || !/^[a-zA-Z0-9_-]{1,200}$/.test(token)) return null
      try {
        const detail = await tempEmailRequest(`/read/${encodeURIComponent(token)}`, accessToken)
        const mail = detail.mail || detail.message || detail.email || detail
        const text = findMailValue(detail, ['plain_body', 'body_text', 'bodytext', 'content_text', 'text', 'message_text', 'body', 'content', 'message'])
        const html = findMailValue(detail, ['html_body', 'body_html', 'content_html', 'message_html', 'html'])
        return {
          token,
          from: findMailValue(detail, ['from', 'sender', 'from_email', 'fromemail']) || mail.from || '',
          subject: findMailValue(detail, ['subject', 'title', 'mail_subject']) || mail.subject || '(Tanpa subjek)',
          // Temp Email 14 mengirim plain_body/html_body. Utamakan teks biasa
          // supaya body dan URL verifikasi dapat langsung dibaca tanpa HTML mentah.
          text,
          html,
          links: extractSafeLinks(html, text)
        }
      } catch (err) {
        console.warn(`[INBOX] gagal membaca pesan ${token}: ${err.message}`)
        return { token, from: '', subject: 'Pesan baru', text: 'Detail pesan belum dapat dimuat.' }
      }
    }))
    const visibleMails = mails.filter(Boolean)
    console.log(`[INBOX] mailbox memuat ${visibleMails.length} pesan; expired=${Boolean(data.expired)}`)
    return res.json({ ok: true, mails: visibleMails, expired: Boolean(data.expired) })
  } catch (err) {
    return res.status(502).json({ ok: false, message: err.message })
  }
})

app.post('/api/amprem7/send', async (req, res) => {
  const email = (req.body?.email || '').trim()
  if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })
  const apikey = config.amprem7ApiKey
  if (!apikey) return res.status(400).json({ ok: false, message: 'API key amprem7 belum diset. Edit config.js dan isi amprem7ApiKey.' })
  try {
    const url = `https://api.theresav.eu/api/premium/alightmotion/send?email=${encodeURIComponent(email)}&apikey=${encodeURIComponent(apikey)}`
    const { data } = await getJSON(url)
    if (isApiFailure(data)) return res.status(502).json({ ok: false, message: data.message || data.error || 'Gagal mengirim link' })
    return res.json({ ok: true, email, message: data.message })
  } catch (err) {
    return res.status(500).json({ ok: false, message: err.message })
  }
})

app.post('/api/amprem7/verify', async (req, res) => {
  const email = (req.body?.email || '').trim()
  const link = (req.body?.link || '').trim()
  if (!validEmail(email)) return res.status(400).json({ ok: false, message: 'Email tidak valid' })
  if (!validLink(link)) return res.status(400).json({ ok: false, message: 'Link tidak valid' })
  const apikey = config.amprem7ApiKey
  if (!apikey) return res.status(400).json({ ok: false, message: 'API key amprem7 belum diset. Edit config.js dan isi amprem7ApiKey.' })
  try {
    const url = `https://api.theresav.eu/api/premium/alightmotion/verify?email=${encodeURIComponent(email)}&link=${encodeURIComponent(link)}&apikey=${encodeURIComponent(apikey)}`
    const { data } = await getJSON(url)
    if (isApiFailure(data)) return res.status(502).json({ ok: false, message: data.message || data.error || 'Verifikasi gagal' })
    return res.json({ ok: true, email, message: data.message })
  } catch (err) {
    return res.status(500).json({ ok: false, message: err.message })
  }
})

const HOST = process.env.HOST || '0.0.0.0'

// ---------- Global error handler supaya server gak crash ----------
process.on('uncaughtException', (err) => {
  console.error('[UNCAUGHT]', err.message)
})
process.on('unhandledRejection', (err) => {
  console.error('[UNHANDLED]', err?.message || err)
})

// Cari IP lokal supaya gampang diakses dari HP lain (1 wifi)
function getLocalIP() {
  try {
    const nets = os.networkInterfaces()
    for (const iface of Object.values(nets)) {
      for (const cfg of iface) {
        if (cfg.family === 'IPv4' && !cfg.internal) return cfg.address
      }
    }
  } catch {}
  return null
}

app.listen(PORT, HOST, () => {
  const localIP = HOST === '0.0.0.0' ? getLocalIP() : null
  console.log(`🌐 Amprem Web jalan di:`)
  console.log(`   Lokal:    http://localhost:${PORT}`)
  if (localIP) {
    console.log(`   Jaringan: http://${localIP}:${PORT}`)
  }
})
