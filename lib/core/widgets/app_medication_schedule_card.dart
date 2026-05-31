import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Kartu jadwal minum obat yang *reusable*, modular, dan terstandardisasi.
///
/// Widget ini memvisualisasikan data jadwal minum obat baik untuk halaman Beranda
/// (HomeView) maupun Riwayat Pengobatan (HistoryView), mendukung kondisi kartu aktif
/// (sorotan hijau), tanda verifikasi PMO (Pemberi Minum Obat), serta penyesuaian otomatis
/// badge status obat ('Di minum', 'Terlewat', 'Segera').
class AppMedicationScheduleCard extends StatelessWidget {
  /// Nama obat (misal: "Obat TBC - Isoniazid").
  final String medName;

  /// Waktu jadwal (format bisa berupa "HH:mm:ss" atau "HH:mm").
  /// Widget ini akan otomatis menormalkannya menjadi format "HH:mm".
  final String scheduleTime;

  /// Status obat hari ini ('Di minum', 'Terlewat', atau 'Segera').
  final String status;

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
    this.isVerified = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Normalisasi format waktu (mengambil HH:mm dari HH:mm:ss jika ada)
    final timeStr = scheduleTime.length >= 5 ? scheduleTime.substring(0, 5) : scheduleTime;

    // Menentukan warna latar belakang badge berdasarkan status
    Color badgeBg = AppColor.warning;
    if (status == 'Di minum') badgeBg = AppColor.success;
    if (status == 'Terlewat') badgeBg = AppColor.error;

    final cardChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        children: [
          // Icon indikator di sebelah kiri
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: status == 'Di minum'
                  ? AppColor.success
                  : (isActive
                      ? AppColor.white.withOpacity(0.2)
                      : AppColor.lightGray),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'Di minum' ? Icons.check : Icons.medical_services_outlined,
              size: 16,
              color: status == 'Di minum'
                  ? AppColor.white
                  : (isActive ? AppColor.white : AppColor.neutralGray),
            ),
          ),
          const SizedBox(width: 14),

          // Nama obat & Badge verifikasi
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    medName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColor.white : AppColor.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
          ),

          // Badge status obat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColor.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Jam alarm & waktu
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
