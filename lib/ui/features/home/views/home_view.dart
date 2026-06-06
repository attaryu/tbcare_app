import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dialog_info_row.dart';
import '../../../../core/widgets/app_medication_schedule_card.dart';
import '../../notification/view_models/notification_view_model.dart';
import '../view_models/home_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.isLoading && viewModel.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    final user = viewModel.user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Gagal memuat data beranda:\n${viewModel.error ?? "Data pengguna kosong"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColor.error, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final dateStr = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    // Hitung Sisa Hari & Label Kepatuhan
    String remainingDayText = 'Estimasi belum tersedia';
    final activeTreatment = viewModel.activeTreatment;
    if (activeTreatment != null) {
      final predEndStr = activeTreatment['prediction_end_date'] as String?;
      if (predEndStr != null) {
        final predEnd = DateTime.tryParse(predEndStr);
        if (predEnd != null) {
          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);
          final predEndMidnight = DateTime(predEnd.year, predEnd.month, predEnd.day);
          final remaining = predEndMidnight.difference(todayMidnight).inDays;
          remainingDayText = remaining > 0
              ? '$remaining hari lagi menuju selesai'
              : 'Jadwal selesai hari ini';
        }
      }
    }

    final rate = viewModel.complianceRate;
    String complianceLabel;
    if (rate >= 90) {
      complianceLabel = 'Luar biasa!';
    } else if (rate >= 75) {
      complianceLabel = 'Pertahankan!';
    } else if (rate >= 50) {
      complianceLabel = 'Butuh peningkatan';
    } else {
      complianceLabel = 'Perlu perhatian!';
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColor.primaryLight,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user.name.split(' ')[0]}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.darkGray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColor.neutralGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final notifVM = context.watch<NotificationViewModel>();
                      final unreadCount = notifVM.unreadCount;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: AppColor.white,
                              ),
                              onPressed: () => context.push('/notifications'),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColor.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: AppColor.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Requirement 1: Alert Banner (Jika belum punya pengawas atau masih pending)
              if (!viewModel.hasSupervisor) ...[
                Builder(builder: (context) {
                  final isPending = viewModel.supervisorInfo != null &&
                      viewModel.supervisorInfo!['status'] == 'pending';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFFFF8E1)
                          : AppColor.white,
                      border: Border.all(
                        color: isPending
                            ? const Color(0xFFFFCC02)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFCC02)
                                : AppColor.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPending
                                ? Icons.hourglass_top_rounded
                                : Icons.info_outline,
                            size: 16,
                            color: isPending
                                ? AppColor.darkGray
                                : AppColor.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isPending
                                ? 'Permintaan pengawasan sedang menunggu persetujuan.'
                                : 'Anda belum terhubung dengan Pengawas.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isPending
                                  ? const Color(0xFF5D4037)
                                  : AppColor.darkGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!isPending) ...[
                          const SizedBox(width: 8),
                          AppButton(
                            text: 'Hubungkan',
                            width: null,
                            height: 36,
                            borderRadius: 8,
                            onPressed: () =>
                                _showConnectSupervisorModal(context, viewModel),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 28),
              ],

              // Requirement 2 & 3: Jadwal Terdekat
              const Text(
                'Jadwal terdekat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              _buildNextScheduleCard(context, viewModel),
              const SizedBox(height: 28),

              // Kemajuan Pengobatan
              const Text(
                'Kemajuan Pengobatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hari Berjalan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${viewModel.daysPassed} Hari',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remainingDayText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tingkat kepatuhan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${viewModel.complianceRate.round()}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complianceLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Aksi Cepat
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Aksi Cepat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickActionCard(
                            icon: Icons.alarm,
                            label: 'Atur\nJadwal',
                            onTap: () =>
                                context.push('/profile/medication-schedules'),
                          ),
                          const SizedBox(width: 14),
                          _buildQuickActionCard(
                            icon: Icons.shield_outlined,
                            label: 'Hubungi\nPengawas',
                            onTap: () {
                              if (viewModel.hasSupervisor) {
                                _showSupervisorInfoModal(context, viewModel);
                              } else {
                                _showConnectSupervisorModal(context, viewModel);
                              }
                            },
                          ),
                          const SizedBox(width: 14),
                          _buildQuickActionCard(
                            icon: Icons.edit_note_outlined,
                            label: 'Catat\nGejala',
                            onTap: () => context.go('/symptoms'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Jadwal Harian
              const Text(
                'Jadwal Harian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 12),

              if (viewModel.schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.lightGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Belum ada jadwal obat yang diatur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColor.neutralGray, fontSize: 14),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildDailyScheduleCard(
                      context,
                      viewModel.schedules[index],
                      viewModel,
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextScheduleCard(BuildContext context, HomeViewModel viewModel) {
    final nextList = viewModel.nextSchedules;
    if (nextList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primary),
        ),
        child: const Text(
          'Semua jadwal obat hari ini telah selesai!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: nextList.map((next) {
        final medName = next['med_name'] ?? 'Obat TBC';
        final timeStr =
            (next['schedule_time'] as String?)?.substring(0, 5) ?? '00:00';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showMedicationDetailModal(context, next, viewModel),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          medName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColor.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$timeStr WIB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Buttons Row
                  Row(
                    children: [
                      if (viewModel.isAlarmTriggering) ...[
                        Expanded(
                          child: AppButton(
                            text: 'Tunda 5 menit',
                            color: AppButtonColor.warning,
                            onPressed: () {
                              viewModel.snoozeMedication();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pengingat ditunda 5 menit'),
                                  backgroundColor: AppColor.warning,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (viewModel.isWithin30MinsSimulation)
                        Expanded(
                          child: AppButton(
                            text: 'Konfirmasi minum obat',
                            onPressed: () {
                              context.push(
                                '/confirm-medication',
                                extra: {
                                  'scheduleId': next['id'],
                                  'medName': medName,
                                  'scheduleTime': timeStr,
                                  'homeViewModel': viewModel,
                                },
                              );
                            },
                          ),
                        )
                      else
                        const Expanded(
                          child: Text(
                            'Belum waktunya konfirmasi minum obat.',
                            style: TextStyle(
                              color: AppColor.neutralGray,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColor.primary, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyScheduleCard(
    BuildContext context,
    Map<String, dynamic> sched,
    HomeViewModel viewModel,
  ) {
    final name = sched['med_name'] ?? 'Obat TBC';
    final timeStr = sched['schedule_time'] as String? ?? '00:00:00';
    final status = sched['today_status'] as String? ?? 'Segera';
    final isNext = viewModel.nextSchedules.any((ns) => ns['id'] == sched['id']);
    final isVerified = sched['is_verified'] == true;

    return AppMedicationScheduleCard(
      medName: name,
      scheduleTime: timeStr,
      status: status,
      isVerified: isVerified,
      isActive: isNext,
      onTap: () => _showMedicationDetailModal(context, sched, viewModel),
    );
  }

  void _showConnectSupervisorModal(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    final codeCtrl = TextEditingController();

    AppDialog.custom(
      context,
      barrierDismissible: false,
      builder: (dialogContext) => ListenableBuilder(
        listenable: viewModel,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hubungkan Pengawas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 20),
            const Text(
              'Masukkan kode unik pengawas yang diberikan oleh petugas atau PMO Anda untuk terhubung dalam pengawasan obat.',
              style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeCtrl,
              enabled: !viewModel.isLoading,
              decoration: InputDecoration(
                labelText: 'Kode Pengawas',
                hintText: 'TBC-XXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColor.primary,
                    width: 2,
                  ),
                ),
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
                    isDisabled: viewModel.isLoading,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Kirim Permintaan',
                    height: 48,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) return;
                      try {
                        await viewModel.connectSupervisor(code);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Permintaan pengawasan berhasil dikirim!',
                              ),
                              backgroundColor: AppColor.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColor.error,
                            ),
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

  void _showSupervisorInfoModal(BuildContext context, HomeViewModel viewModel) {
    final info = viewModel.supervisorInfo;
    if (info == null) return;

    AppDialog.info(
      context,
      title: 'Informasi Pengawas',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDialogInfoRow(
            label: 'Nama',
            value: info['name'] ?? '-',
          ),
          AppDialogInfoRow(
            label: 'Telepon',
            value: info['telephone'] ?? '-',
          ),
          AppDialogInfoRow(
            label: 'Status Koneksi',
            value: info['status'] ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showMedicationDetailModal(
    BuildContext context,
    Map<String, dynamic> sched,
    HomeViewModel viewModel,
  ) {
    final medName = sched['med_name'] ?? 'Obat TBC';
    final timeStr =
        (sched['schedule_time'] as String?)?.substring(0, 5) ?? '00:00';
    final dosage = sched['dosage'] ?? '1 Tablet / Kaplet';
    final instructions = sched['instructions'] ?? 'Diminum sesudah makan';

    AppDialog.custom(
      context,
      barrierDismissible: false,
      builder: (dialogContext) => ListenableBuilder(
        listenable: viewModel,
        builder: (_, __) {
          final currentSched = viewModel.schedules.firstWhere(
            (s) => s['id'] == sched['id'],
            orElse: () => sched,
          );
          final status = currentSched['today_status'] ?? 'Segera';

          Color statusColor = AppColor.darkGray;
          if (status == 'Di minum') statusColor = AppColor.success;
          if (status == 'Terlewat') statusColor = AppColor.error;
          if (status == 'Segera') statusColor = AppColor.warning;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services, color: AppColor.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      medName,
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
              AppDialogInfoRow(label: 'Waktu Minum', value: '$timeStr WIB'),
              AppDialogInfoRow(label: 'Dosis', value: dosage),
              AppDialogInfoRow(label: 'Aturan Pakai', value: instructions),
              AppDialogInfoRow(
                label: 'Status Hari Ini',
                value: status,
                valueColor: statusColor,
                isLast: true,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Tutup',
                      variant: AppButtonVariant.outline,
                      height: 48,
                      isDisabled: viewModel.isLoading,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  if (status != 'Di minum') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Konfirmasi',
                        height: 48,
                        isLoading: viewModel.isLoading,
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.push(
                            '/confirm-medication',
                            extra: {
                              'scheduleId': sched['id'],
                              'medName': medName,
                              'scheduleTime': timeStr,
                              'homeViewModel': viewModel,
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
