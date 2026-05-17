# TB Care App 💊🤖

Sistem deteksi dini tuberkulosis (TB) berbasis Artificial Intelligence (AI) untuk memantau kepatuhan minum obat dan mendeteksi risiko relaps (kambuh). Aplikasi ini membantu pasien TB dan petugas kesehatan dalam memastikan pengobatan yang tepat dan berkelanjutan.

## 🚀 Fitur Utama

- **📸 Deteksi Wajah & Verifikasi Pengobatan**: Memastikan pasien yang benar sedang minum obat.
- **📊 Pemantauan Kepatuhan**: Mencatat riwayat minum obat untuk mencegah putus obat.
- **🛡️ Prediksi Risiko Kambuh**: Algoritma AI menganalisis data pasien untuk mengidentifikasi risiko relaps dini.
- **💬 Asisten Virtual Cerdas**: Chatbot yang siap menjawab pertanyaan seputar TB dan pengobatan.
- **🔔 Notifikasi Pengingat**: Pengingat rutin untuk minum obat agar tidak terlewat.

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter 3.38.3
- **Bahasa Pemrograman**: Dart 3.10.1
- **Database**: Supabase
- **AI & Machine Learning**:
  - TensorFlow Lite (Pemrosesan Gambar)
  - Google Gemini API (Pemrosesan Bahasa & Analisis Data)

## 📡 Konfigurasi Database

Pastikan file `.env` berada di direktori root proyek dan memiliki kredensial Supabase sebagai berikut:

```ini
SUPABASE_URL=https://your_project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```
