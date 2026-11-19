# Dear, Us — Online starter

Starter ini menghubungkan UI vintage Dear, Us ke Supabase. Ia belum di-deploy; Anda perlu membuat project Supabase dan hosting (contoh: Vercel).

## 1. Buat project Supabase
1. Buat project baru di https://supabase.com/
2. Buka SQL Editor, jalankan seluruh isi `supabase/schema.sql`.
3. Buka Authentication > Providers > Email dan aktifkan Email.
4. Buka Authentication > Users. Daftarkan dua akun (email masing-masing) melalui UI aplikasi setelah konfigurasi awal atau buat melalui dashboard.

## 2. Daftarkan dua anggota private
1. Di Authentication > Users, salin UUID kedua akun.
2. Di SQL Editor, jalankan query contoh di bagian bawah `supabase/schema.sql`, ganti placeholder dengan UUID yang benar.
3. Simpan UUID couple yang dikembalikan oleh INSERT ke tabel `couples`.

## 3. Jalankan website
- Deploy `index.html` sebagai static site (misalnya Vercel: https://vercel.com/).
- Buka website. Masukkan Project URL, anon/publishable key, dan Couple ID.
- Kedua orang login memakai akun masing-masing.

## Keamanan penting
- Hanya gunakan Supabase anon/publishable key di browser. JANGAN masukkan `service_role` / secret key.
- RLS membatasi data ke anggota couple.
- Isi surat berada di tabel terpisah `capsule_contents`; policy SELECT memeriksa tanggal dari database (`opens_at <= UTC date`). UI tidak mengambil isi sebelum waktunya.
- Prototype ini belum menyertakan undangan pasangan otomatis, reset password kustom, upload foto, backup, atau verifikasi keamanan independen. Untuk penggunaan sangat sensitif, lakukan audit dan pengujian sebelum memasukkan kenangan pribadi.
- File ini tidak otomatis membuat akun atau meng-host website. Jangan kirim password atau service-role key lewat chat.
