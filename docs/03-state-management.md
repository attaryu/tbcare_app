# 03 - State Management

Dokumen ini menjelaskan standar implementasi _state management_ menggunakan **Bloc/Cubit** (`flutter_bloc`). Tujuannya adalah mencegah _memory leak_, menjaga sinkronisasi data, dan menghindari _error_ navigasi.

## 1. Penempatan `BlocProvider`

Kita menggunakan dua lokasi utama untuk mendistribusikan Cubit ke _Widget Tree_:

### A. Global Level (`main.dart`)

- **Kapan:** Untuk _state_ yang bersifat _app-wide_ (berdampak ke banyak fitur) atau mengontrol _flow_ utama aplikasi.
- **Contoh:** `SessionCubit` (Auth), `CategoryCubit` (Master Data).

### B. Router-Level (`app_router.dart`)

- **Kapan:** Untuk _state_ spesifik per modul, per tab navigasi (_ShellRoute_), atau satu halaman tertentu.
- **Contoh:** `LoginCubit`, `DashboardMetricCubit`, `AddTransactionCubit`.

---

## 2. Siklus Hidup & Golden Rules Injeksi

Siklus hidup Cubit terbagi dua: **Long-Lived** (hidup selama aplikasi berjalan) dan **Temporary** (hanya hidup saat halaman dibuka). Untuk mencegah _lifecycle issue_ (seperti data dari form lama muncul kembali atau _state_ tidak sengaja ter-_dispose_), ikuti **Golden Rules** berikut:

### Rule 1: Long-Lived Cubit

Digunakan untuk Global State, atau halaman utama di dalam Tab (_ShellRoute_) yang _state_-nya harus dipertahankan saat berpindah tab (Contoh: Dashboard, Transaction History, Fixed Cost).

- **Di Injectable:** Wajib gunakan `@singleton` atau `@lazySingleton`.
- **Di Provider:** Wajib gunakan `BlocProvider.value`.
  ```dart
  BlocProvider.value(value: getIt<DashboardMetricCubit>())
  ```
- **Why:** Method `.value` mencegah `flutter_bloc` melakukan _dispose_ otomatis saat _widget tree_ dilepas, karena kita mendeklarasikan bahwa siklus hidupnya diatur oleh luar (_Dependency Injection_ / Get It).

### Rule 2: Temporary Cubit

Digunakan untuk form tunggal atau halaman detail (Contoh: Add Transaction, Transaction Detail, Login).

- **Di Injectable:** Wajib gunakan `@injectable`.
- **Di Provider:** Wajib gunakan `BlocProvider` dengan `create`.
  ```dart
  BlocProvider(create: (_) => getIt<AddTransactionCubit>())
  ```
- **Why:** `@injectable` membuat _instance_ baru setiap kali dipanggil (data bersih). Fungsi `create` menjadikan `flutter_bloc` sebagai pemilik Cubit tersebut, sehingga **otomatis di-dispose** (memori dibersihkan) ketika pengguna keluar dari halaman.

---

## 3. Komunikasi Antar Cubit (Event Bus Pattern)

**Masalah:** Cubit terpisah per fitur, tetapi data harus saling sinkron. (Misal: Sukses tambah transaksi di `AddTransactionCubit` harus seketika memperbarui saldo di `DashboardMetricCubit`).

**Solusi:** Gunakan **Event Bus Pattern** untuk memancarkan kejadian global.

**1. Emit Event (Pengirim)**
Cubit yang mengubah data memancarkan sinyal ke _Event Bus_ setelah proses berhasil.

```dart
// Di dalam AddTransactionCubit
emit(AddTransactionSuccess());
getIt<EventBus>().fire(TransactionAddedEvent()); // Sinyal global
```

**2. Listen Event (Penerima)**
Cubit yang membutuhkan data terbaru me-_listen_ sinyal tersebut untuk melakukan _re-fetch_.

```dart
// Di dalam DashboardMetricCubit
DashboardMetricCubit() : super(DashboardMetricInitial()) {
  _eventSub = getIt<EventBus>().on<TransactionAddedEvent>().listen((_) {
    fetchDashboardMetrics(); // Tarik data terbaru
  });
}

@override
Future<void> close() {
  _eventSub?.cancel(); // Wajib di-cancel
  return super.close();
}
```

- **Why Event Bus:** Menjaga _loose coupling_ (Cubit tidak saling import/memanggil). Modul tetap independen, sangat mudah di-_scale_, tetapi UI tetap sinkron dan _real-time_.
- **Why Cancel Subscription:** Mencegah _memory leak_ di mana Cubit terus mendengar sinyal meskipun _instance_-nya sudah mati.
