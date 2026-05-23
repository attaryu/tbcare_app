import 'package:flutter/material.dart';
import '../theme/app_color.dart';
import 'app_button.dart';

/// Komponen Dialog Kustom yang *reusable*, modular, dan terstandardisasi untuk TBCare.
///
/// Dirancang secara ergonomis dengan *Named Constructor* (Factory-Style) agar
/// memudahkan penggunaan bagi pengembang maupun **Agentic AI** secara presisi.
///
/// ### Jenis Dialog yang Didukung:
/// 1. **`AppDialog.confirm`**: Mengonfirmasi aksi sensitif/destruktif (Logout, Hapus, dsb).
/// 2. **`AppDialog.info`**: Menampilkan detail data informasi terstruktur dengan rapi.
/// 3. **`AppDialog.custom`**: Kerangka kosong fleksibel dengan sudut membulat standar untuk desain bebas.
///
/// ### Contoh Penggunaan:
/// ```dart
/// // Contoh 1: Konfirmasi Destruktif (Hapus Catatan)
/// AppDialog.confirm(
///   context,
///   title: 'Hapus Catatan',
///   message: 'Apakah Anda yakin ingin menghapus catatan gejala ini?',
///   confirmLabel: 'Hapus',
///   confirmColor: AppButtonColor.danger,
///   onConfirm: () => _deleteLog(),
/// );
/// ```
class AppDialog extends StatelessWidget {
  /// Widget konten inti yang diletakkan di bagian tengah dialog.
  final Widget content;

  /// Tingkat kebulatan sudut dialog. Standarnya adalah `20.0`.
  final double borderRadius;

  /// Jarak isi dialog ke batas luar dialog. Standarnya adalah `EdgeInsets.all(24.0)`.
  final EdgeInsetsGeometry padding;

  const AppDialog({
    super.key,
    required this.content,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 36.0,
      ),
      child: Padding(padding: padding, child: content),
    );
  }

  /// Menampilkan dialog dengan efek animasi transisi masuk (Fade + Scale) premium.
  static Future<T?> _show<T>({
    required BuildContext context,
    required Widget Function(BuildContext dialogContext) builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'AppDialogBarrier',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) =>
          builder(dialogContext),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(scaleCurve),
            child: child,
          ),
        );
      },
    );
  }

  /// **1. Constructor Konfirmasi (Confirm Dialog)**
  ///
  /// Digunakan untuk meminta keputusan Ya/Tidak kepada pengguna sebelum mengeksekusi
  /// sebuah tindakan penting (seperti keluar akun, hapus data, atau konfirmasi penyelesaian).
  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    AppButtonColor confirmColor = AppButtonColor.primary,
    IconData? icon,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return _show<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: confirmColor == AppButtonColor.danger
                      ? AppColor.error.withOpacity(0.15)
                      : confirmColor == AppButtonColor.warning
                          ? AppColor.warning.withOpacity(0.15)
                          : AppColor.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: confirmColor == AppButtonColor.danger
                      ? AppColor.error
                      : confirmColor == AppButtonColor.warning
                          ? AppColor.warning
                          : AppColor.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGray,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.neutralGray,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelLabel,
                    variant: AppButtonVariant.outline,
                    height: 48,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onCancel?.call();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: confirmLabel,
                    color: confirmColor,
                    height: 48,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onConfirm();
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

  /// **2. Constructor Informasi (Info Dialog)**
  ///
  /// Digunakan untuk menyajikan data terstruktur lengkap atau pengumuman penting
  /// kepada pengguna (seperti informasi profil detail, jadwal obat, atau kode pengawasan).
  static Future<void> info(
    BuildContext context, {
    required String title,
    required Widget content,
    IconData? icon,
    Color iconColor = AppColor.primary,
    String closeLabel = 'Tutup',
    bool barrierDismissible = true,
  }) {
    return _show<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColor.darkGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: closeLabel,
              variant: AppButtonVariant.outline,
              height: 48,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  /// **3. Constructor Kustom (Custom Dialog)**
  ///
  /// Menyediakan wadah dialog bebas dengan kebulatan sudut standar untuk diisi konten kustom penuh.
  static Future<T?> custom<T>(
    BuildContext context, {
    required Widget Function(BuildContext dialogContext) builder, // <-- Menggunakan builder untuk kontrol context penuh
    double borderRadius = 20.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24.0),
    bool barrierDismissible = true,
  }) {
    return _show<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog(
        borderRadius: borderRadius,
        padding: padding,
        content: builder(dialogContext), // <-- Merender konten kustom dengan dialogContext
      ),
    );
  }
}
