import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Kartu jadwal minum obat yang *reusable*, modular, dan terstandardisasi.
///
/// Widget ini memvisualisasikan data jadwal minum obat baik untuk halaman Beranda
/// (HomeView) maupun Riwayat Pengobatan (HistoryView), mendukung kondisi kartu aktif
/// (sorotan hijau), tanda verifikasi PMO (Pemberi Minum Obat), serta penyesuaian otomatis
/// badge status obat ('Tepat waktu', 'Terlewat', 'Segera').
class AppMedicationScheduleCard extends StatelessWidget {
  /// Nama obat (misal: "Obat TBC - Isoniazid").
  final String medName;

  /// Waktu jadwal (format bisa berupa "HH:mm:ss" atau "HH:mm").
  /// Widget ini akan otomatis menormalkannya menjadi format "HH:mm".
  final String scheduleTime;

  /// Status obat hari ini ('Tepat waktu', 'Terlewat', atau 'Segera').
  final String status;

  /// Waktu ketika obat diminum / dikonfirmasi.
  final String? takenTime;

  /// Status verifikasi PMO/petugas kesehatan.
  final bool isVerified;

  /// Menunjukkan apakah kartu ini merupakan jadwal terdekat yang sedang aktif/berlangsung.
  /// Jika `true`, kartu akan disorot dengan warna hijau brand (`AppColor.primary`).
  final bool isActive;

  /// Aksi callback ketika kartu ditekan.
  /// Jika bernilai `null`, kartu akan bersifat statis (tidak reaktif/tidak dapat diklik)
  /// yang cocok digunakan pada halaman riwayat (HistoryView).
  final VoidCallback? onTap;

  const AppMedicationScheduleCard({
    super.key,
    required this.medName,
    required this.scheduleTime,
    required this.status,
    this.takenTime,
    this.isVerified = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Normalisasi format waktu (mengambil HH:mm dari HH:mm:ss jika ada)
    final timeStr = scheduleTime.length >= 5 ? scheduleTime.substring(0, 5) : scheduleTime;

    String displayStatus = status;
    bool isLate = false;
    String? takenHourMin;
    if (takenTime != null && status == 'Tepat waktu') {
      final parsedTaken = DateTime.tryParse(takenTime!)?.toLocal();
      if (parsedTaken != null) {
        final takenHourStr = parsedTaken.hour.toString().padLeft(2, '0');
        final takenMinStr = parsedTaken.minute.toString().padLeft(2, '0');
        takenHourMin = '$takenHourStr:$takenMinStr';

        final parts = scheduleTime.split(':');
        if (parts.isNotEmpty) {
          final schedHour = int.tryParse(parts[0]) ?? 0;
          final schedMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          if (parsedTaken.hour > schedHour ||
              (parsedTaken.hour == schedHour && parsedTaken.minute > schedMin)) {
            isLate = true;
            displayStatus = 'Terlambat';
          }
        }
      }
    }

    // Menentukan warna latar belakang badge berdasarkan status
    Color badgeBg = AppColor.warning;
    if (displayStatus == 'Tepat waktu') badgeBg = AppColor.success;
    if (displayStatus == 'Terlewat') badgeBg = AppColor.error;
    if (displayStatus == 'Terlambat') badgeBg = AppColor.warning;

    // Menentukan background dan icon indikator sebelah kiri
    Color indicatorBg = AppColor.lightGray;
    if (status == 'Tepat waktu') {
      indicatorBg = isLate ? AppColor.warning : AppColor.success;
    } else if (isActive) {
      indicatorBg = AppColor.white.withOpacity(0.2);
    }

    final cardChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? AppColor.primary : AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColor.primary : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon indikator di sebelah kiri
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: indicatorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'Tepat waktu' ? Icons.check : Icons.medical_services_outlined,
              size: 16,
              color: status == 'Tepat waktu'
                  ? AppColor.white
                  : (isActive ? AppColor.white : AppColor.neutralGray),
            ),
          ),
          const SizedBox(width: 14),

          // Kolom utama: nama obat (atas) + status & waktu (bawah)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baris atas: Nama obat + badge verified
                Row(
                  children: [
                    Text(
                      medName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColor.white : AppColor.darkGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: isActive ? AppColor.white : AppColor.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Baris bawah: Badge status + jam
                Row(
                  children: [
                    // Badge status obat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        displayStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Jam alarm & waktu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alarm,
                              size: 14,
                              color: isActive ? AppColor.white : AppColor.darkGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$timeStr WIB',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isActive ? AppColor.white : AppColor.darkGray,
                              ),
                            ),
                          ],
                        ),
                        if (takenHourMin != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Diminum: $takenHourMin WIB',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? AppColor.white.withOpacity(0.8) : AppColor.neutralGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return cardChild;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: cardChild,
    );
  }
}
