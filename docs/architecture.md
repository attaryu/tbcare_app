# TBCare — Arsitektur Aplikasi

**Collaborative Monitoring System untuk Pasien Tuberkulosis (TBC)**

---

## 1. Pola Arsitektur: MVVM

Aplikasi ini menggunakan pola arsitektur **MVVM (Model-View-ViewModel)** untuk memisahkan logika bisnis dari tampilan (UI). Hal ini memfasilitasi pengujian, pemeliharaan, dan skalabilitas.

### Komponen Utama:

1.  **View (Tampilan)**:
    -   Bertanggung jawab untuk merender UI menggunakan Flutter Widgets.
    -   Mendengarkan perubahan dari ViewModel dan memperbarui tampilan.
    -   Mengirimkan input pengguna ke ViewModel.
    -   Lokasi: `lib/ui/features/[feature]/views/`.

2.  **ViewModel**:
    -   Mengelola state aplikasi untuk View tertentu.
    -   Berkomunikasi dengan Repository untuk mengambil atau menyimpan data.
    -   Menggunakan `ChangeNotifier` dari paket `provider` untuk memberitahu View saat terjadi perubahan data (`notifyListeners()`).
    -   Lokasi: `lib/ui/features/[feature]/view_models/`.

3.  **Model (Data)**:
    -   Representasi objek data (misal: `User`, `SymptomLog`, `TreatmentPeriod`).
    -   Mencakup logika serialisasi JSON (`fromJson`, `toJson`).
    -   Lokasi: `lib/data/models/`.

4.  **Repository (Abstraksi Data)**:
    -   Menyediakan API bersih bagi ViewModel untuk berinteraksi dengan data.
    -   Menyembunyikan detail implementasi sumber data (misal: Supabase, Local Storage).
    -   Lokasi: `lib/data/repositories/`.

5.  **Service (Layanan Eksternal)**:
    -   Wrapper untuk pustaka pihak ketiga atau layanan eksternal.
    -   Contoh: `SupabaseService` untuk interaksi langsung dengan Supabase SDK.
    -   Lokasi: `lib/data/services/`.

---

## 2. Struktur Folder

Proyek ini diatur secara modular berdasarkan fitur dan lapisan (layers):

```text
lib/
├── core/               # Utilitas, tema, konfigurasi, dan widget global
│   ├── config/         # Konfigurasi lingkungan (Env)
│   ├── theme/          # Definisi warna, font, dan tema aplikasi
│   ├── widgets/        # Widget yang dapat digunakan di seluruh aplikasi
│   └── shell/          # Kerangka navigasi (misal: Bottom Nav Bar)
├── data/               # Lapisan data (Data Layer)
│   ├── models/         # Model data (POJO/Data Classes)
│   ├── repositories/   # Abstraksi akses data
│   └── services/       # Integrasi API/Supabase
├── ui/                 # Lapisan Tampilan (UI Layer)
│   ├── core/           # Komponen UI global atau helper UI
│   ├── features/       # Modul fitur (MVVM per fitur)
│   │   ├── auth/       # Fitur Autentikasi
│   │   ├── home/       # Fitur Beranda
│   │   ├── symptoms/   # Fitur Pencatatan Gejala
│   │   └── ...
│   └── router/         # Konfigurasi navigasi (GoRouter)
└── main.dart           # Titik masuk aplikasi (Entry point)
```

---

## 3. Teknologi Kunci

-   **Flutter**: Framework UI utama.
-   **Supabase**: Backend-as-a-Service (Database, Auth, Storage).
-   **Provider**: State management untuk menghubungkan View dan ViewModel.
-   **GoRouter**: Navigasi deklaratif dan routing berbasis URL.
-   **Bcrypt**: Digunakan untuk validasi password manual di sisi aplikasi (karena kebutuhan khusus bypass Supabase Auth di fase tertentu).
-   **Intl**: Dukungan lokalisasi dan format data/waktu.

---

## 4. Alur Navigasi dan Routing

Navigasi dikelola secara terpusat di `lib/ui/router/`. Kami menggunakan `GoRouter` untuk mendukung:
-   **Deep Linking**: Navigasi langsung ke halaman tertentu.
-   **Nested Navigation**: Menggunakan `ShellRoute` untuk halaman dengan navigasi bawah (Bottom Navigation Bar) yang tetap.
-   **Guard/Redirect**: Memastikan pengguna telah login sebelum mengakses fitur utama.

---

## 5. Keamanan

1.  **RBAC (Role-Based Access Control)**: Hak akses diatur di level database (PostgreSQL RLS) dan divalidasi di aplikasi berdasarkan peran pengguna (Pasien/Pengawas).
2.  **Hashing Password**: Password disimpan dalam bentuk hash menggunakan algoritma yang aman.
3.  **Data Medis**: Akses ke data log kepatuhan dan gejala dibatasi hanya untuk pasien pemilik data dan pengawas yang telah disetujui.

---

_Dokumentasi ini mencerminkan arsitektur TBCare per Mei 2026._
