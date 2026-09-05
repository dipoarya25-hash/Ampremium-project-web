// Konfigurasi khusus website ini - gak ada hubungannya sama project bot
// WhatsApp manapun. Cuma butuh API key buat tiap variant.

export const config = {
  // API key komunitas gratisan (dibagi bareng semua pengguna) dari
  // free-restapi.biz.id - dipakai halaman amprem6.html. Bisa kena
  // limit/habis kapan aja karena dipakai rame-rame. Kalau amprem6
  // mulai gagal terus, daftar punya sendiri (gratis):
  //   1. https://free-restapi.biz.id/users/register
  //   2. Login, buka https://free-restapi.biz.id/profile
  //   3. Salin API key-nya, ganti nilai di bawah ini
  amprem6ApiKey: 'SK-5A6D0C0FB6D7B35A71B9A70F',

  // API key untuk amprem2 (api.haidarxd.my.id). Daftar di situs tsb
  // kalau belum punya, lalu isi di sini.
  amprem2ApiKey: '',

  // API key untuk amprem7 (api.theresav.eu). Daftar di situs tsb
  // kalau belum punya, lalu isi di sini.
  //   1. Buka https://api.theresav.eu
  //   2. Daftar/login, buat API key
  //   3. Salin API key-nya, ganti nilai di bawah ini
  amprem7ApiKey: ''
}
