import 'package:flutter/material.dart';
import '../theme/app_color.dart';

/// Sebuah baris informasi berpasangan label-value yang dirancang untuk
/// digunakan di dalam komponen [AppDialog], khususnya untuk [AppDialog.info].
///
/// Widget ini mempermudah penyajian data terstruktur (seperti detail profil,
/// informasi pengawas, dsb) secara bersih, rapi, dan konsisten.
///
/// ### Contoh Penggunaan:
/// ```dart
/// Column(
///   children: [
///     AppDialogInfoRow(
///       label: 'Nama Lengkap',
///       value: 'Budi Santoso',
///     ),
///     AppDialogInfoRow(
///       label: 'Status Adisi',
///       value: 'Aktif',
///       valueColor: AppColor.success,
///     ),
///     AppDialogInfoRow(
///       label: 'Nomor HP',
///       value: '081234567890',
///       isLast: true, // Menghilangkan divider di paling bawah
///     ),
///   ],
/// )
/// ```
class AppDialogInfoRow extends StatelessWidget {
  /// Label deskripsi informasi di sisi kiri (misal: "Nama", "Status").
  /// Ditampilkan dengan warna abu-abu netral ([AppColor.neutralGray]).
  final String label;

  /// Nilai informasi di sisi kanan (misal: "Budi", "Aktif").
  /// Ditampilkan tebal (bold) dengan warna gelap ([AppColor.darkGray]) secara bawaan.
  final String value;

  /// Warna teks khusus untuk [value]. Jika diset, akan menimpa warna gelap default.
  /// Sangat berguna untuk menonjolkan status sukses, peringatan, atau bahaya.
  final Color? valueColor;

  /// Menentukan apakah baris ini merupakan item terakhir dalam daftar.
  /// Jika `true`, garis pemisah ([Divider]) di bagian bawah baris tidak akan digambar.
  /// Standarnya bernilai `false`.
  final bool isLast;

  const AppDialogInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColor.neutralGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppColor.darkGray,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColor.lightGray.withOpacity(0.6),
          ),
      ],
    );
  }
}
