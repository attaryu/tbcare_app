import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';

/// Pilihan varian bentuk visual untuk [AppButton].
enum AppButtonVariant {
  /// Varian tombol solid dengan warna latar belakang penuh.
  primary,

  /// Varian tombol outline dengan warna latar belakang putih dan border berwarna sesuai tema warna yang dipilih.
  outline,
}

/// Pilihan skema warna tema untuk [AppButton].
enum AppButtonColor {
  /// Warna brand hijau ([AppColor.primary])
  primary,

  /// Warna peringatan oranye ([AppColor.warning])
  warning,

  /// Warna bahaya/destruktif merah ([AppColor.error])
  danger,
}

/// Tombol kustom yang *reusable*, modular, dan modern untuk aplikasi TBCare.
///
/// Widget ini didesain agar mudah digunakan oleh pengembang (manusia) maupun
/// Agentic AI. Dilengkapi dengan dukungan state yang lengkap.
///
/// ### Fitur & State yang Didukung:
/// 1. **Variant & Color**: Mengombinasikan [AppButtonVariant] (primary, outline) dan [AppButtonColor] (primary, warning, danger).
/// 2. **Teks & Icon**: Dapat menampilkan teks saja, icon saja, atau kombinasi keduanya (posisi icon di kiri teks).
/// 3. **State Loading**: Menampilkan [CircularProgressIndicator] secara otomatis di tengah tombol
///    dengan warna yang menyesuaikan varian aktif, serta menonaktifkan interaksi klik.
/// 4. **State Disabled**: Menonaktifkan tombol, meredupkan warna background menjadi abu-abu terang,
///    dan mengubah warna teks/icon menjadi abu-abu netral.
/// 5. **Haptic Feedback**: Memberikan getaran fisik ringan (`HapticFeedback.lightImpact`) saat ditekan demi UX yang lebih premium.
///
/// ### Contoh Penggunaan:
///
/// ```dart
/// // 1. Tombol Primary Hijau Standar dengan Teks saja
/// AppButton(
///   text: 'Masuk',
///   onPressed: () => _performLogin(),
/// )
///
/// // 2. Tombol Outline Hijau dengan Icon dan Teks
/// AppButton(
///   text: 'Kirim Laporan',
///   variant: AppButtonVariant.outline,
///   icon: Icon(Icons.send, size: 20),
///   onPressed: () => _sendReport(),
/// )
///
/// // 3. Tombol Destruktif Merah Solid (Danger)
/// AppButton(
///   text: 'Hapus Akun',
///   color: AppButtonColor.danger,
///   onPressed: () => _deleteAccount(),
/// )
///
/// // 4. Tombol Peringatan Oranye Outline (Warning Outline)
/// AppButton(
///   text: 'Tunda Alarm',
///   variant: AppButtonVariant.outline,
///   color: AppButtonColor.warning,
///   onPressed: () => _snooze(),
/// )
/// ```
class AppButton extends StatelessWidget {
  /// Label teks yang akan ditampilkan di dalam tombol.
  final String? text;

  /// Widget pendukung (biasanya berupa [Icon]) yang diletakkan di sebelah kiri teks.
  /// Jika [text] juga diberikan, akan otomatis diberi jarak (spacing) 8px dari teks.
  final Widget? icon;

  /// Fungsi callback ketika tombol ditekan.
  /// Jika diset `null`, tombol akan berada dalam kondisi tidak aktif (disabled).
  final VoidCallback? onPressed;

  /// Varian bentuk tombol (primary atau outline). Standarnya adalah [AppButtonVariant.primary].
  final AppButtonVariant variant;

  /// Warna dasar tombol. Standarnya adalah [AppButtonColor.primary] (Hijau).
  final AppButtonColor color;

  /// Menunjukkan apakah tombol sedang dalam proses memuat (loading).
  /// Jika `true`, tombol menampilkan [CircularProgressIndicator] dan tidak bisa diklik.
  final bool isLoading;

  /// Menunjukkan apakah tombol dinonaktifkan secara manual.
  /// Jika `true`, tombol akan di-greyout dan tidak bisa diklik.
  final bool isDisabled;

  /// Lebar tombol. Secara default bernilai [double.infinity] agar memenuhi ruang horizontal yang tersedia.
  final double? width;

  /// Tinggi tombol. Secara default bernilai `52.0` untuk kenyamanan sentuhan jari (*touch target*).
  final double height;

  /// Tingkat kebulatan sudut tombol. Secara default bernilai `12.0` (rounded).
  final double borderRadius;

  /// Menentukan apakah tombol memicu getaran fisik halus pada perangkat saat ditekan.
  /// Standarnya bernilai `true`.
  final bool enableHaptic;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.color = AppButtonColor.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.height = 52.0,
    this.borderRadius = 12.0,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    // Tombol nonaktif jika isDisabled=true, isLoading=true, atau onPressed tidak disediakan (null)
    final bool isButtonDisabled = isDisabled || isLoading || onPressed == null;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    if (isButtonDisabled) {
      backgroundColor = AppColor.lightGray;
      foregroundColor = AppColor.neutralGray;
      borderSide = BorderSide.none;
    } else {
      // Dapatkan warna tema dasarnya
      final Color baseThemeColor = _resolveBaseColor();

      switch (variant) {
        case AppButtonVariant.outline:
          backgroundColor = AppColor.white;
          foregroundColor = baseThemeColor;
          borderSide = BorderSide(color: baseThemeColor, width: 1);
          break;
        default:
          backgroundColor = baseThemeColor;
          foregroundColor = AppColor.white;
          borderSide = BorderSide.none;
          break;
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isButtonDisabled
            ? null
            : () {
                if (enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: AppColor.lightGray,
          disabledForegroundColor: AppColor.neutralGray,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      if (text != null) const SizedBox(width: 8),
                    ],
                    if (text != null)
                      Flexible(
                        child: Text(
                          text!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _resolveBaseColor() {
    switch (color) {
      case AppButtonColor.warning:
        return AppColor.warning;
      case AppButtonColor.danger:
        return AppColor.error;
      default:
        return AppColor.primary;
    }
  }
}
