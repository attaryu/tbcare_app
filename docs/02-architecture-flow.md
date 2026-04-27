# 02 - Architecture Flow

Dokumen ini menjelaskan struktur arsitektur, aliran data (_flow_), dan prinsip-prinsip pengembangan yang diterapkan dalam proyek ini. Proyek ini mengadopsi variasi dari **Clean Architecture** yang disesuaikan untuk efisiensi pengembangan.

## 1. Layering & Folder Structure

Aplikasi dibagi menjadi dua bagian utama: `core/` untuk hal-hal yang bersifat global/shared, dan `features/` untuk fungsionalitas spesifik bisnis.

### A. Folder `core/`

Folder ini berisi kode dasar yang digunakan oleh seluruh fitur dalam aplikasi.

- **`constants/`**: Menyimpan variabel global, konfigurasi environment, dan teks statis.
- **`network/`**: Konfigurasi HTTP client (Dio), `interceptors` (seperti logging atau auth interceptor), dan pengelolaan koneksi.
- **`error/`**: Definisi `Exception` dan `Failure`, serta `ErrorHandler` untuk standarisasi pesan error.
- **`theme/`**: Definisi `AppColors`, `AppTextStyles`, dan konfigurasi `ThemeData`.
- **`utils/`**: Fungsi pembantu (_helper_) seperti `CurrencyFormatter`, `LocalStorage`, dan `Logger`.
- **`widgets/`**: _Atomic widgets_ atau komponen UI yang bersifat _reusable_ di banyak fitur (Button, TextField, Alert, dsb).
- **`routes/`**: Pengelolaan navigasi pusat menggunakan `AppRouter`.

### B. Folder `features/`

Setiap fitur (misal: `auth`, `transaction`, `dashboard`) memiliki struktur internal yang mengikuti prinsip Clean Architecture:

1. **`domain/`**: Layer paling dalam yang berisi aturan bisnis murni.
   - **`entities/`**: Objek data inti yang digunakan di UI.
   - **`repositories/`**: Kontrak (_interface_) dari repositori.
   - **`usecases/`**: Logika bisnis spesifik untuk satu aksi (misal: `LoginUseCase`).
2. **`data/`**: Layer implementasi data.
   - **`models/`**: Ekstensi dari _entity_ yang menyertakan logika JSON serialization (`fromJson`, `toJson`).
   - **`repositories/`**: Implementasi konkret dari kontrak di layer domain.
   - **`data_sources/`**: Pengambilan data mentah dari `remote` (API) atau `local` (Storage/DB).
3. **`presentation/`**: Layer UI dan State Management.
   - **`cubit/`**: Pengelola state menggunakan library Bloc/Cubit.
   - **`pages/`**: Halaman utama aplikasi.
   - **`widgets/`**: Komponen UI yang spesifik hanya untuk fitur tersebut.

---

## 2. Pragmatic Rule: "Direct Repository Access"

Untuk menjaga produktivitas dan mengurangi _boilerplate code_ yang berlebihan, proyek ini menerapkan aturan pragmatis:

- **Standard Flow**: `Presentation (Cubit) -> Domain (UseCase) -> Data (Repository)`. Digunakan untuk logika bisnis yang kompleks atau melibatkan validasi berlapis.
- **Pragmatic Flow**: `Presentation (Cubit) -> Data (Repository)`. Diperbolehkan untuk operasi **CRUD simpel** (seperti mengambil list kategori atau menghapus item sederhana) di mana tidak ada logika bisnis tambahan di level UseCase.
- **Tujuannya**: Mengurangi jumlah file yang perlu dibuat tanpa mengorbankan _testability_ dan _readability_.

---

## 3. Dependency Injection (DI)

Proyek ini menggunakan **Get It** sebagai _service locator_ dan **Injectable** untuk pendaftaran komponen secara otomatis.

### Cara Kerja:

1. **Annotasi**: Gunakan annotasi `@injectable`, `@lazySingleton`, atau `@singleton` pada _class_ yang ingin didaftarkan.
   - `@lazySingleton` biasanya digunakan untuk Repository dan Data Source.
   - `@injectable` digunakan untuk Cubit atau UseCase.
2. **Pendaftaran Otomatis**: Kita tidak perlu mendaftarkan setiap class secara manual di `injection_container.dart`. Cukup jalankan perintah _code generation_:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Pendaftaran Manual**: Untuk library pihak ketiga (seperti `Dio` atau `SharedPreferences`), pendaftaran dilakukan melalui `External Module` di dalam folder `core/` atau `injection_container.dart`.
4. **Penggunaan**: Gunakan fungsi `getIt<TypeName>()` untuk mengambil instance yang sudah terdaftar.

---

## 4. Aliran Data (Flow of Data)

1. **User Interaction**: User menekan tombol di `Page` (Presentation).
2. **Method Call**: `Page` memanggil fungsi di `Cubit`.
3. **Data Request**: `Cubit` memanggil `UseCase` atau langsung ke `Repository`.
4. **Repository Implementation**: `Repository` meminta data ke `RemoteDataSource`.
5. **Response**: Data dari API dikonversi menjadi `Model`, dikembalikan sebagai `Entity`.
6. **State Update**: `Cubit` menerima data, mengubah state (misal: `Loading` -> `Loaded`), dan `UI` melakukan _rebuild_ secara otomatis.

---

## 5. Penanganan Error (Error Handling)

- Semua error dari layer `Data` harus ditangkap dan dikonversi menjadi `Failure` (objek yang dipahami layer UI).
- `Cubit` bertanggung jawab untuk mengubah `Failure` menjadi pesan yang bisa dibaca pengguna di layar.
