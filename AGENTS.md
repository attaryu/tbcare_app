# TBCare AI Coding Agent Guidelines 🤖💊

Selamat datang di repositori TBCare. File ini berisi instruksi, standar arsitektur, dan konvensi coding aktual yang wajib dipatuhi oleh semua **Agentic AI** maupun asisten AI coding (seperti OpenCode, Claude Code, dan Copilot).

---

## 1. Arsitektur Aktual: MVVM + Provider

Aplikasi ini menggunakan pola arsitektur **MVVM (Model-View-ViewModel)** murni dengan **Provider** sebagai state management.

- **View** (`lib/ui/features/[feature]/views/`): Hanya bertugas melakukan render UI secara deklaratif. Bersifat pasif (*Dumb UI*). Wajib membaca state dari ViewModel via `context.watch<VM>()` atau `context.read<VM>()`.
- **ViewModel** (`lib/ui/features/[feature]/view_models/`): Mengelola state halaman dan mewarisi `ChangeNotifier`. Bertanggung jawab memanggil *Repository*, memperbarui state `_isLoading` & `_error`, serta memicu `notifyListeners()`.
- **Model** (`lib/data/models/`): Representasi data mentah yang aman dengan fungsi serialisasi JSON (`fromJson`/`toJson`).
- **Repository** (`lib/data/repositories/`): Sumber data bersih terabstraksi yang menghubungkan ViewModel dengan data lokal atau Supabase API.

---

## 2. Standar & Konvensi Dialog Aktual

Semua dialog di dalam folder `lib/ui/features/` wajib terstandardisasi menggunakan komponen UI global `AppDialog` (`lib/core/widgets/app_dialog.dart`).

### A. Jenis Dialog yang Didukung
1. **`AppDialog.confirm`**: Konfirmasi aksi sensitif/destruktif (Logout, Hapus, Selesai).
2. **`AppDialog.info`**: Menyajikan informasi detail data terstruktur statis.
3. **`AppDialog.custom`**: Wadah dialog kustom dengan sudut membulat standar untuk desain dinamis/bebas.

*Catatan: Konstruktor `AppDialog.form` telah dihapus secara resmi karena redundansi state.*

### B. Aturan Emas Dialog Form & API (Pattern 3)
Jika sebuah dialog berfungsi sebagai formulir input data atau melakukan pemanggilan API (async/await), wajib mematuhi aturan berikut:

1. **Wajib Menggunakan `AppDialog.custom` + `ListenableBuilder`**
   Bungkus seluruh konten dialog dengan `ListenableBuilder` yang mendengarkan `ChangeNotifier` ViewModel secara langsung. Hindari membuat state lokal (`StatefulBuilder` atau `ValueNotifier` baru) secara berlebihan.
2. **Anti-Tutup Luar (`barrierDismissible: false`)**
   Dialog yang memicu operasi tulis/API tidak boleh ditutup secara tidak sengaja dengan mengklik area luar (background).
3. **Tombol Reaktif Loading State**
   Tombol konfirmasi/kirim wajib menampilkan loading spinner dengan mengikat parameter `isLoading: viewModel.isLoading`.
4. **Tombol Batal Dikunci saat Loading**
   Tombol Batal/Tutup wajib dikunci (`isDisabled: viewModel.isLoading`) saat API sedang bekerja agar tidak mengacaukan proses navigasi.
5. **Form Fields Dikunci saat Loading**
   Semua `TextField` atau widget input dalam dialog wajib dikunci via parameter `enabled: !viewModel.isLoading` ketika state ViewModel sedang loading.
6. **Urutan `Navigator.pop` yang Aman**
   `Navigator.pop` hanya boleh dipanggil **setelah** operasi async/API mengembalikan respons sukses di dalam blok `try`. Jangan memanggil `Navigator.pop` sebelum await.

---

## 3. Contoh Implementasi Pattern 3 (Koneksi Pengawas)

```dart
void _showConnectSupervisorModal(BuildContext context, HomeViewModel viewModel) {
  final codeCtrl = TextEditingController();

  AppDialog.custom(
    context,
    barrierDismissible: false, // Wajib false untuk API dialog
    builder: (dialogContext) => ListenableBuilder(
      listenable: viewModel, // Mendengarkan ViewModel aktual
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hubungkan Pengawas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColor.darkGray),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1.2),
          const SizedBox(height: 20),
          TextField(
            controller: codeCtrl,
            enabled: !viewModel.isLoading, // Terkunci saat loading
            decoration: InputDecoration(
              labelText: 'Kode Pengawas',
              hintText: 'TBC-XXXXXX',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Batal',
                  variant: AppButtonVariant.outline,
                  height: 48,
                  isDisabled: viewModel.isLoading, // Terkunci saat loading
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Kirim',
                  height: 48,
                  isLoading: viewModel.isLoading, // Menampilkan loading spinner
                  onPressed: () async {
                    final code = codeCtrl.text.trim();
                    if (code.isEmpty) return;
                    try {
                      await viewModel.connectSupervisor(code);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext); // Pop HANYA jika sukses
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Koneksi berhasil!'),
                            backgroundColor: AppColor.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColor.error),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

---

## 4. Referensi Tambahan
- Detail pola folder dan file: `@docs/architecture.md`
- Skema PostgreSQL v3 database: `@docs/database.md`
