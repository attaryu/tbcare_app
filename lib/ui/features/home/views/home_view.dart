import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../auth/view_models/auth_view_model.dart';
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

    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

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
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, color: AppColor.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Belum ada notifikasi baru.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Requirement 1: Alert Banner (Jika belum punya pengawas)
              if (!viewModel.hasSupervisor) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    border: Border.all(color: Colors.grey.shade300),
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
                        decoration: const BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, size: 16, color: AppColor.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Anda belum terhubung dengan Pengawas.',
                          style: TextStyle(fontSize: 13, color: AppColor.darkGray, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showConnectSupervisorModal(context, viewModel),
                        child: const Text('Hubungkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Requirement 2 & 3: Jadwal Terdekat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal terdekat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkGray,
                    ),
                  ),
                  // Simulasi Toggles
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Simulasi Waktu 30 Menit',
                        icon: Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: viewModel.isWithin30MinsSimulation ? AppColor.primary : AppColor.neutralGray,
                        ),
                        onPressed: viewModel.toggleWithin30MinsSimulation,
                      ),
                      IconButton(
                        tooltip: 'Simulasi Alarm Aktif',
                        icon: Icon(
                          Icons.alarm_on_outlined,
                          size: 20,
                          color: viewModel.isAlarmTriggering ? AppColor.warning : AppColor.neutralGray,
                        ),
                        onPressed: viewModel.toggleAlarmSimulation,
                      ),
                    ],
                  ),
                ],
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
                            'Hari yang terlewat',
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${viewModel.daysPassed} Hari',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '40 hari menuju kesehatan',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
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
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${viewModel.complianceRate.round()}%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pertahankan!',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
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
                          child: const Icon(Icons.bolt, color: Colors.white, size: 20),
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
                            onTap: () => context.push('/profile/treatment-periods'),
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
                    return _buildDailyScheduleCard(context, viewModel.schedules[index], viewModel.nextSchedule);
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
    final next = viewModel.nextSchedule;
    if (next == null) {
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
          style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      );
    }

    final medName = next['med_name'] ?? 'Obat TBC';
    final timeStr = (next['schedule_time'] as String?)?.substring(0, 5) ?? '00:00';

    return InkWell(
      onTap: () => _showMedicationDetailModal(context, next),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        viewModel.snoozeMedication();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pengingat ditunda 5 menit'), backgroundColor: AppColor.warning),
                        );
                      },
                      child: const Text('Tunda 5 menit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.white, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (viewModel.isWithin30MinsSimulation)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        try {
                          await viewModel.confirmMedicationTaken(next['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Konfirmasi minum obat berhasil!'), backgroundColor: AppColor.success),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColor.error),
                            );
                          }
                        }
                      },
                      child: const Text('Konfirmasi minum obat', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.white, fontSize: 13)),
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      'Belum waktunya konfirmasi minum obat.',
                      style: TextStyle(color: AppColor.neutralGray, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildDailyScheduleCard(BuildContext context, Map<String, dynamic> sched, Map<String, dynamic>? nextSched) {
    final name = sched['med_name'] ?? 'Obat TBC';
    final timeStr = (sched['schedule_time'] as String?)?.substring(0, 5) ?? '00:00';
    final status = sched['today_status'] as String? ?? 'Segera';

    final isNext = nextSched != null && nextSched['id'] == sched['id'];

    Color badgeBg = AppColor.warning;
    if (status == 'Di minum') badgeBg = AppColor.success;
    if (status == 'Terlewat') badgeBg = AppColor.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isNext ? AppColor.primary : AppColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNext ? AppColor.primary : Colors.grey.shade300),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: status == 'Di minum' ? AppColor.success : (isNext ? AppColor.white.withOpacity(0.2) : AppColor.lightGray),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'Di minum' ? Icons.check : Icons.medical_services_outlined,
              size: 16,
              color: status == 'Di minum' ? AppColor.white : (isNext ? AppColor.white : AppColor.neutralGray),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isNext ? AppColor.white : AppColor.darkGray,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.white),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.alarm, size: 14, color: isNext ? AppColor.white : AppColor.darkGray),
          const SizedBox(width: 4),
          Text(
            '$timeStr WIB',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isNext ? AppColor.white : AppColor.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectSupervisorModal(BuildContext context, HomeViewModel viewModel) {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hubungkan Pengawas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.darkGray),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColor.neutralGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Masukkan kode unik pengawas yang diberikan oleh petugas atau PMO Anda untuk terhubung dalam pengawasan obat.',
                style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: 'Kode Pengawas',
                  hintText: 'TBC-XXXXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColor.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final code = codeCtrl.text.trim();
                    if (code.isEmpty) return;
                    Navigator.pop(context);
                    try {
                      await viewModel.connectSupervisor(code);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Permintaan pengawasan berhasil dikirim!'), backgroundColor: AppColor.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColor.error),
                        );
                      }
                    }
                  },
                  child: const Text('Kirim Permintaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupervisorInfoModal(BuildContext context, HomeViewModel viewModel) {
    final info = viewModel.supervisorInfo;
    if (info == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Pengawas', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${info['name'] ?? '-'}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Telepon: ${info['telephone'] ?? '-'}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Status Koneksi: ${info['status'] ?? '-'}', style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _showMedicationDetailModal(BuildContext context, Map<String, dynamic> sched) {
    final medName = sched['med_name'] ?? 'Obat TBC';
    final timeStr = (sched['schedule_time'] as String?)?.substring(0, 5) ?? '00:00';
    final dosage = sched['dosage'] ?? '1 Tablet / Kaplet';
    final instructions = sched['instructions'] ?? 'Diminum sesudah makan';
    final status = sched['today_status'] ?? 'Segera';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColor.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medical_services, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(medName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColor.darkGray)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailItem('Waktu Minum', '$timeStr WIB', Icons.alarm),
            const SizedBox(height: 12),
            _buildDetailItem('Dosis', dosage, Icons.medication_outlined),
            const SizedBox(height: 12),
            _buildDetailItem('Aturan Pakai', instructions, Icons.info_outline),
            const SizedBox(height: 12),
            _buildDetailItem('Status Hari Ini', status, Icons.check_circle_outline, isStatus: true, statusText: status),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isStatus = false, String? statusText}) {
    Color valColor = AppColor.darkGray;
    if (isStatus) {
      if (statusText == 'Di minum') valColor = AppColor.success;
      if (statusText == 'Terlewat') valColor = AppColor.error;
      if (statusText == 'Segera') valColor = AppColor.warning;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColor.neutralGray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColor.neutralGray)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
