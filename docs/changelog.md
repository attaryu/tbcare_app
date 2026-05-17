# TBCare — Changelog & Riwayat Perubahan

Dokumen ini mencatat riwayat pembaruan, perbaikan bug, dan penyesuaian arsitektur pada aplikasi mobile **TBCare** untuk rilis versi terbaru.

---

## [v1.2.0-dev] - 17 Mei 2026

### ✨ Fitur Baru & UI Premium (Peran Pasien)
- **Halaman Beranda (`HomeView`)**:
  - Implementasi *alert banner* dinamis di bagian atas untuk pasien yang belum terhubung dengan pengawas.
  - Implementasi pop-up Modal Input Kode Pengawas saat tombol "Hubungkan" ditekan.
  - Fitur simulasi interaktif "Tunda 5 Menit" dan "Konfirmasi Minum Obat" pada bagian Jadwal Terdekat.
  - Penambahan Modal Box Rincian Obat yang muncul ketika pengguna menyentuh area jadwal pengobatan terdekat.
  - Penyempurnaan tata letak (UX) kartu **Aksi Cepat** menggunakan struktur vertikal dan `IntrinsicHeight` untuk mencegah *overflow* pada layar fisik *smartphone*.

- **Halaman Riwayat Pengobatan (`HistoryView`)**:
  - Implementasi antarmuka riwayat pengobatan premium dengan skema warna *mint green* (`#E6F8F3`) dan hijau zamrud.
  - *Banner* persentase kepatuhan bulanan besar yang menghitung perbandingan aktual dosis terverifikasi.
  - Grid 4 Kartu Statistik: Terverifikasi (Hijau), Tidak terverifikasi (Mint), Terlambat (Kuning), dan Terlewat (Merah).
  - Kalender interaktif bulanan dengan indikator *heatmap* (*Penuh*, *Sebagian*, *Terlewat*, *Mendatang*) serta navigasi antar bulan.
  - Daftar riwayat pengobatan harian yang responsif terhadap tanggal yang dipilih pada kalender.

- **Halaman Riwayat Gejala (`SymptomListView`)**:
  - Implementasi *Sticky Header* menggunakan `CustomScrollView` dan `SliverPersistentHeader`, menjaga bilah pencarian dan filter tetap berada di atas layar saat daftar di-scroll.
  - Penataan filter *chips* (*Semua, Normal, Ringan, Parah*) sejajar di tengah (`MainAxisAlignment.center`).
  - Pembuatan **Modal Box Detail Riwayat Gejala** premium untuk menggantikan navigasi halaman baru saat item riwayat diketuk, dilengkapi tombol Hapus dan Edit.

### 🛠️ Penyesuaian Database & Ketahanan Arsitektur (Supabase v3)
- **Kepatuhan Terhadap Skema v3 (`compliance_logs`)**:
  - Penghapusan rujukan kolom usang `log_date` pada repositori Beranda dan Riwayat, beralih sepenuhnya ke pencarian rentang waktu riil menggunakan kolom `taken_at` (`TIMESTAMP`).
  - Kewajiban penyertaan kolom `med_name` (`VARCHAR 255 NOT NULL`) pada seluruh proses insersi catatan kepatuhan.
- **Kepatuhan Terhadap Skema Periode Pengobatan (`treatment_periods`)**:
  - Mengoreksi penamaan field dari `period_type` menjadi field resmi `name` (mis. "Fase Intensif") sesuai `docs/database.md`.
  - Mengoreksi kolom tanggal prediksi selesai menjadi `prediction_end_date`.
- **Pencegahan *Crash* Relasional (`PostgrestException`)**:
  - Mengganti seluruh penggunaan metode `.single()` atau `.maybeSingle()` yang berisiko memicu *exception* `PGRST116` dengan metode `.select().list` yang 100% aman di seluruh repositori (`HomeRepository`, `HistoryRepository`, `SymptomRepository`, `TreatmentRepository`, `ProfileRepository`).
- **Seeder Otomatis Berbasis Cloud**:
  - Implementasi logika *seeder* dinamis pada repositori yang otomatis mengisi `treatment_periods`, `medication_schedules`, dan `compliance_logs` jika akun pasien belum memiliki riwayat data di Supabase Cloud.

### 🐛 Perbaikan Bug Khusus Perangkat Fisik
- Penambahan inisialisasi `initializeDateFormatting('id_ID', null)` di `main.dart` untuk mengatasi `LocaleDataException` pada perangkat fisik Android (Samsung M11).
- Perbaikan *RenderFlex overflow* pada kartu profil dan navigasi bawah.

---
