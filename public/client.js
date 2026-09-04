// Helper generic dipakai semua halaman amprem*.html.
// Setiap halaman punya script sendiri-sendiri yang manggil fungsi di sini -
// ini BUKAN state/router yang nyatuin halaman jadi satu SPA, cuma
// kumpulan fungsi utilitas biasa.

async function apiCall(path, body) {
  const res = await fetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {})
  })
  let data
  try {
    data = await res.json()
  } catch {
    throw new Error(`Server balas format gak dikenal (HTTP ${res.status})`)
  }
  if (!res.ok || data.ok === false) {
    throw new Error(data.message || `Gagal (HTTP ${res.status})`)
  }
  return data
}

async function pasteFromClipboard(inputEl) {
  try {
    const text = await navigator.clipboard.readText()
    if (text) inputEl.value = text.trim()
  } catch {
    inputEl.focus()
    // Browser lama/gak ngizinin akses clipboard - biarin user paste manual (Ctrl+V)
  }
}

function showNotice(el, type, html) {
  el.className = `notice show ${type}`
  el.innerHTML = html
}

function hideNotice(el) {
  el.className = 'notice'
  el.innerHTML = ''
}

function resultList(pairs) {
  return `<ul class="result-list">${pairs.map(([k, v]) => `<li><span class="k">${k}</span><span class="v">${v}</span></li>`).join('')}</ul>`
}

// Kartu hasil sukses gaya "receipt" (Order ID, UID, dsb). CATATAN JUJUR:
// "Order ID" dan "UID Akun" di sini di-generate ACAK di sisi browser
// buat tampilan doang - backend yang kita pakai (dapjimotionpro,
// free-restapi, theresav) gak pernah balikin data semacam itu, jadi ini
// BUKAN nomor order resmi dari Alight Motion.
function randomCode(len, charset) {
  charset = charset || 'abcdefghijklmnopqrstuvwxyz0123456789'
  let out = ''
  for (let i = 0; i < len; i++) out += charset[Math.floor(Math.random() * charset.length)]
  return out
}

function renderSuccessCard(container, info) {
  const orderId = randomCode(6, 'abcdefghijklmnopqrstuvwxyz') + '-' + randomCode(5, '0123456789')
  const uid = randomCode(28, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789')
  const rows = [
    ['Email Akun', info.email],
    ['Order ID', orderId],
    ['UID Akun', uid],
    ['Masa Berlaku', info.duration || '1 Tahun Penuh']
  ]

  container.className = ''
  container.innerHTML =
    '<div class="success-card">' +
      '<div class="success-head">' +
        '<div class="success-icon">&#10003;</div>' +
        '<div><div class="success-title">Premium Pro Aktif!</div>' +
        '<div class="success-sub">Alight Motion Annual VIP Subscription</div></div>' +
      '</div>' +
      '<div class="success-divider"></div>' +
      '<div class="success-rows">' +
        rows.map(function (r) { return '<div class="success-row"><span class="k">' + r[0] + '</span><span class="v">' + r[1] + '</span></div>' }).join('') +
        '<div class="success-row"><span class="k">Status</span><span class="v status">ACTIVE / PRO UNLOCKED</span></div>' +
      '</div>' +
      '<p class="success-note">Order ID &amp; UID Akun dibuat lokal buat tampilan, bukan data resmi dari Alight Motion.</p>' +
      '<button class="copy-proof-btn" type="button">Salin Bukti &amp; Detail Akun</button>' +
    '</div>'

  const btn = container.querySelector('.copy-proof-btn')
  btn.addEventListener('click', function () {
    const text = 'Alight Motion Premium Pro Aktif\n' +
      rows.map(function (r) { return r[0] + ': ' + r[1] }).join('\n') +
      '\nStatus: ACTIVE / PRO UNLOCKED'
    navigator.clipboard.writeText(text).then(function () {
      btn.classList.add('copied')
      btn.textContent = 'Tersalin!'
      setTimeout(function () {
        btn.classList.remove('copied')
        btn.textContent = 'Salin Bukti & Detail Akun'
      }, 1800)
    }).catch(function () {})
  })
}
