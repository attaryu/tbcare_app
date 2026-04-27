# 04 - Development Rules

Dokumen ini menetapkan aturan ketat dan standar operasional dalam menulis kode untuk proyek ini. Setiap pengembang wajib mematuhi aturan ini untuk menjaga konsistensi dan kualitas kode.

## 1. Dumb UI: Strict Separation of Concerns

Kita menerapkan prinsip **Dumb UI**. Widget hanya boleh bertanggung jawab atas representasi visual dan interaksi pengguna, tanpa memiliki pengetahuan tentang _business logic_.

- **Tanggung Jawab Widget**:
  - Memicu fungsi pada `Cubit` saat ada interaksi pengguna (contoh: `onPressed`).
  - Melakukan _render_ berdasarkan _state_ yang dikirim oleh `Cubit`.
  - Logika UI sederhana seperti _layout_ berdasarkan ukuran layar atau _toggle_ visibilitas sederhana (menggunakan _flag_ dari _state_).
- **Larangan Ketat**:
  - **Dilarang** melakukan pemanggilan API secara langsung di dalam Widget.
  - **Dilarang** melakukan kalkulasi data mentah (misal: menjumlahkan total transaksi) di dalam Widget. Lakukan ini di `UseCase` atau `Cubit`.
  - **Dilarang** menyalin logika bisnis ke dalam blok `if-else` di dalam metode `build`. Gunakan _state_ yang sudah diolah.

## 2. Theming & Styling: No Hardcoded Values

Untuk menjaga konsistensi desain dan kemudahan kustomisasi, dilarang keras menggunakan nilai _hardcoded_ untuk warna, ukuran, dan gaya teks.

- **AppColors**: Gunakan kelas `AppColors` untuk semua kebutuhan warna. Jangan gunakan `Color(0xFF...)` atau `Colors.blue` secara langsung.
  - Contoh: `color: AppColors.primary`.
- **AppSizes**: Gunakan `AppSizes` untuk _spacing_, _padding_, _margin_, dan _radius_.
  - Contoh: `SizedBox(height: AppSizes.spacing4)` atau `borderRadius: BorderRadius.circular(AppSizes.radiusMd)`.
- **AppTextStyles**: Gunakan gaya teks yang sudah didefinisikan untuk semua komponen label atau teks.
  - Contoh: `style: AppTextStyles.h1`.
  - Jika perlu mengubah warna teks, gunakan metode `.copyWith(color: ...)` daripada membuat gaya baru.

## 3. Logging & Debugging: Print() is Forbidden

Penggunaan `print()` atau `debugPrint()` secara sembarangan dapat mengotori konsol dan membocorkan informasi sensitif di lingkungan rilis.

- **Aturan**: Dilarang menggunakan `print()`.
- **Solusi**: Gunakan kelas `AppLogger` yang telah disediakan.
- **Level Log**:
  - `Logger.root.info(...)`: Untuk informasi alur aplikasi.
  - `Logger.root.warning(...)`: Untuk kejadian yang tidak diharapkan tapi tidak merusak aplikasi.
  - `Logger.root.severe(...)`: Untuk _error_ fatal yang harus ditangkap.

## 4. Dependency Injection & Code Generation

Proyek ini sangat bergantung pada otomatisasi kode untuk meminimalkan kesalahan manusia.

- **Build Runner**: Setiap kali menambah atau mengubah anotasi `@injectable`, `@lazySingleton`, atau `@singleton`, Anda **harus** menjalankan _build_runner_.
  - Perintah: `dart run build_runner build --delete-conflicting-outputs`.
- **GetIt**: Gunakan `getIt<T>()` untuk mengambil _instance_ dari _repository_, _usecase_, atau _cubit_ (sesuai aturan siklus hidup di dokumen 03).

## 5. Async/Await & Error Handling

- **Asynchrony**: Selalu pilih `async/await` daripada menggunakan `.then()` untuk menjaga keterbacaan kode.
- **Error Mapping**: Setiap _exception_ yang terjadi di layer `Data` (Remote/Local) harus ditangkap dan dikonversi menjadi objek `Failure` sebelum dikirim ke layer `Presentation`.
- **Rethrow**: Gunakan kata kunci `rethrow` hanya jika Anda perlu menangkap _error_ di blok `catch` tetapi tetap ingin meneruskannya ke pemanggil di atasnya.

## 6. Naming Convention (Standard Suffix)

Gunakan akhiran (_suffix_) yang konsisten untuk nama file dan kelas sesuai dengan perannya:

- Halaman UI: `...Page` (Contoh: `LoginPage`).
- Komponen UI: `...Widget` atau nama deskriptif (Contoh: `AppButton`).
- State: `...Cubit` dan `...State`.
- Kontrak Data: `...Repository`.
- Aksi Bisnis: `...UseCase`.

## 7. Import Statements

- **Relative Import**: Gunakan import relatif untuk file dalam folder (misal: `import './app_button.dart';`).
- **Package Import**: Gunakan import paket untuk file yang berada di luar modul (misal: `import 'package:money_management_mobile/domain/usecases/get_user_profile.dart';`).
- **Urutan Import**: Urutkan import berdasarkan kategori:
  1. Dart SDK
  2. Package eksternal
  3. Import internal (proyek)
- **Alias Import**: Jika ada konflik nama, gunakan alias untuk membedakan (misal: `import 'package:money_management_mobile/domain/entities/user.dart' as user_entity;`).
