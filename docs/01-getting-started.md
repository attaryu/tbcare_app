# 01 - Getting Started

Dokumen ini menjelaskan langkah-langkah untuk melakukan persiapan (_setup_) dan menjalankan proyek ini di lingkungan lokal (_local environment_) Anda.

## 1. Persyaratan Sistem & Instalasi

Sebelum memulai, pastikan sistem Anda memenuhi spesifikasi berikut:

- **Flutter SDK**: Versi `3.10.8` atau yang lebih baru.
- **RAM**: Minimal 8GB (direkomendasikan untuk kelancaran kompilasi dan emulator).
- **IDE**: VS Code atau Android Studio dengan ekstensi/plugin Flutter dan Dart yang sudah terpasang.

Untuk memverifikasi versi Flutter Anda, jalankan perintah berikut:

```bash
flutter --version
```

## 2. Generate Code (Build Runner)

Proyek ini menggunakan `injectable` (beserta `get_it`) untuk _Dependency Injection_. Oleh karena itu, Anda **wajib** menjalankan _code generator_ sebelum melakukan kompilasi atau menjalankan aplikasi untuk pertama kalinya.

Jalankan perintah berikut di terminal pada _root directory_ proyek:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

_(Catatan: Anda juga dapat menggunakan perintah `dart run build_runner build --delete-conflicting-outputs`)_

Jika Anda sedang dalam proses pengembangan (_development_) dan sering mengubah dependensi atau modul, gunakan perintah `watch` agar _code generator_ berjalan otomatis setiap kali ada perubahan file:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 3. Konfigurasi Environment

Aplikasi ini membaca konfigurasi _environment_ menggunakan `fromEnvironment` pada saat proses _build_ atau berjalan.

Berikut adalah daftar variabel _environment_ yang tersedia beserta nilai bawaannya (_default value_):

| Variabel                    | Tipe     | Default Value                 | Deskripsi                                                                       |
| :-------------------------- | :------- | :---------------------------- | :------------------------------------------------------------------------------ |
| `APP_ENV`                   | `String` | `development`                 | Status _environment_ saat ini (contoh: `development`, `staging`, `production`). |

### Cara Menjalankan Aplikasi

Untuk memasukkan variabel-variabel di atas saat menjalankan aplikasi, gunakan _flag_ `--dart-define`. Berikut adalah contoh perintah `flutter run` lengkap:

```bash
flutter run \
  --dart-define=APP_ENV="development"
```

**Tips untuk VS Code:**
Agar tidak perlu mengetik panjang setiap kali menjalankan aplikasi, Anda dapat membuat file `.vscode/launch.json` dan memasukkan argumen _environment_ tersebut di dalam `toolArgs`:

```json
{
	"version": "0.2.0",
	"configurations": [
		{
			"name": "TBCare (Dev)",
			"request": "launch",
			"type": "dart",
			"toolArgs": [
				"--dart-define=APP_ENV=development"
			]
		}
	]
}
```
