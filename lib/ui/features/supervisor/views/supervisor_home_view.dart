import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/supervisor_view_model.dart';

class SupervisorHomeView extends StatelessWidget {
  const SupervisorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Consumer<SupervisorViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading &&
                vm.terlewatList.isEmpty &&
                vm.verifikasiList.isEmpty &&
                vm.amanList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => vm.loadData(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  _Header(user: user),
                  const SizedBox(height: 24),
                  const Text(
                    'Status Pengobatan Pasien',
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
                        child: _StatCard(
                          'Terlewat',
                          vm.terlewatCount,
                          AppColor.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          'Butuh Verifikasi',
                          vm.verifikasiCount,
                          AppColor.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          'Aman',
                          vm.amanCount,
                          AppColor.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (vm.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColor.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.error!,
                              style: const TextStyle(
                                color: AppColor.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (vm.terlewatList.isNotEmpty) ...[
                    _SectionHeader('Terlewat'),
                    const SizedBox(height: 12),
                    ...vm.terlewatList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TerlewatCard(item: item, vm: vm),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (vm.verifikasiList.isNotEmpty) ...[
                    _SectionHeader('Menunggu Verifikasi'),
                    const SizedBox(height: 12),
                    ...vm.verifikasiList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VerifikasiCard(item: item, vm: vm),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (vm.amanList.isNotEmpty) ...[
                    _SectionHeader('Aman'),
                    const SizedBox(height: 12),
                    ...vm.amanList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AmanCard(item: item),
                      ),
                    ),
                  ],
                  if (vm.terlewatList.isEmpty &&
                      vm.verifikasiList.isEmpty &&
                      vm.amanList.isEmpty &&
                      !vm.isLoading) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppColor.success.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Semua Pasien Aman',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColor.darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tidak ada jadwal yang terlewat atau\nmenunggu verifikasi hari ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColor.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final dynamic user;
  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
          backgroundColor: AppColor.primaryLight,
          child: user?.photoUrl == null
              ? Text(
                  (user?.name ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${user?.name ?? 'Pengawas'}!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.neutralGray,
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
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColor.white,
              size: 22,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _StatCard(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColor.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColor.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColor.darkGray,
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';
  final parts = timeStr.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]} WIB';
  return timeStr;
}

Future<void> _launchPhone(String? phone) async {
  if (phone == null || phone.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Widget _photoThumbnail(String? url, {Color fallbackColor = AppColor.primary}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 52,
      height: 52,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _thumbnailPlaceholder(fallbackColor),
            )
          : _thumbnailPlaceholder(fallbackColor),
    ),
  );
}

Widget _thumbnailPlaceholder(Color color) {
  return Container(
    color: color.withOpacity(0.12),
    child: Icon(Icons.medication_rounded, color: color, size: 24),
  );
}

void _onIgnore(
  BuildContext context,
  Map<String, dynamic> item,
  SupervisorViewModel vm,
) {
  final escalationId = item['escalation_id'] as int?;
  if (escalationId == null) return;

  AppDialog.confirm(
    context,
    title: 'Abaikan',
    message: 'Tandai bahwa Anda sudah mengetahui keterlambatan ini?',
    confirmLabel: 'Ya, Abaikan',
    onConfirm: () async {
      try {
        await vm.ignoreEscalation(escalationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Keterlambatan telah diabaikan')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColor.error,
            ),
          );
        }
      }
    },
  );
}

void _onVerify(
  BuildContext context,
  Map<String, dynamic> item,
  SupervisorViewModel vm,
) {
  AppDialog.confirm(
    context,
    title: 'Verifikasi Foto',
    message: 'Pastikan foto bukti minum obat valid. Setujui?',
    confirmLabel: 'Setujui',
    onConfirm: () async {
      try {
        await vm.verifyLog(item['log_id'] as int);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verifikasi berhasil')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColor.error,
            ),
          );
        }
      }
    },
  );
}

void _onReject(
  BuildContext context,
  Map<String, dynamic> item,
  SupervisorViewModel vm,
) {
  AppDialog.confirm(
    context,
    title: 'Tolak Verifikasi',
    message: 'Pasien akan diminta mengunggah foto ulang. Lanjutkan?',
    confirmLabel: 'Tolak',
    confirmColor: AppButtonColor.danger,
    onConfirm: () async {
      try {
        await vm.rejectLog(
          item['log_id'] as int,
          item['schedule_time'] as String,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi ditolak, pasien diminta foto ulang'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColor.error,
            ),
          );
        }
      }
    },
  );
}

// ─── Terlewat Card ────────────────────────────────────────────────────────────

class _TerlewatCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final SupervisorViewModel vm;
  const _TerlewatCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['patient_name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColor.error,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['med_name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColor.neutralGray,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColor.neutralGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item['schedule_time'] as String?),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.neutralGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (item['escalation_id'] != null) ...[
            _ActionButton(
              icon: Icons.check_rounded,
              backgroundColor: AppColor.primary,
              iconColor: AppColor.white,
              onTap: () => _onIgnore(context, item, vm),
            ),
            const SizedBox(width: 8),
          ],
          _ActionButton(
            icon: Icons.phone_rounded,
            backgroundColor: AppColor.warning,
            iconColor: AppColor.white,
            onTap: () => _launchPhone(item['telephone'] as String?),
          ),
        ],
      ),
    );
  }
}

// ─── Verifikasi Card ──────────────────────────────────────────────────────────

class _VerifikasiCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final SupervisorViewModel vm;
  const _VerifikasiCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final photoEvidence = item['photo_evidence'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _photoThumbnail(photoEvidence, fallbackColor: AppColor.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['patient_name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColor.warning,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['med_name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColor.neutralGray,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColor.neutralGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item['schedule_time'] as String?),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.neutralGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.close_rounded,
            backgroundColor: AppColor.error,
            iconColor: AppColor.white,
            onTap: () => _onReject(context, item, vm),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.check_rounded,
            backgroundColor: AppColor.primary,
            iconColor: AppColor.white,
            onTap: () => _onVerify(context, item, vm),
          ),
        ],
      ),
    );
  }
}

// ─── Aman Card ────────────────────────────────────────────────────────────────

class _AmanCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AmanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final photoUrl = item['photo_url'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _photoThumbnail(photoUrl, fallbackColor: AppColor.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['patient_name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColor.darkGray,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['med_name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColor.neutralGray,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColor.neutralGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item['schedule_time'] as String?),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.neutralGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
