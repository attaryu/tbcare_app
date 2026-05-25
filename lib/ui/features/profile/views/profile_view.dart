import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dialog_info_row.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/profile_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    if (viewModel.isLoading && viewModel.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    final user = viewModel.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Gagal memuat profil')));
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Profil dan Pengaturan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 24),

              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColor.primaryLight,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.favorite_border_outlined,
                                      size: 14,
                                      color: AppColor.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      viewModel.roleName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.mail_outline,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.telephoneNumber?.isNotEmpty == true
                                    ? user.telephoneNumber!
                                    : 'Belum ada telepon',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section 1: Akun
              _buildSectionTitle('Akun'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildListItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      onTap: () => _showEditProfileDialog(context, viewModel),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    if (viewModel.roleSlug == 'pasien') ...[
                      if (viewModel.supervisorInfo != null)
                        _buildListItem(
                          icon: Icons.people_outline,
                          title: 'Lihat Pengawas',
                          onTap: () =>
                              _showSupervisorDetailsDialog(context, viewModel),
                        )
                      else
                        _buildListItem(
                          icon: Icons.shield_outlined,
                          title: 'Tambah Pengawas',
                          onTap: () =>
                              _showAddSupervisorDialog(context, viewModel),
                        ),
                    ] else if (viewModel.roleSlug == 'pengawas') ...[
                      _buildListItem(
                        icon: Icons.qr_code_outlined,
                        title: 'Kode Pengawasan Saya',
                        onTap: () =>
                            _showSupervisorCodeDialog(context, viewModel),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section 2: Informasi Pengobatan (Hanya untuk pasien)
              if (viewModel.roleSlug == 'pasien') ...[
                _buildSectionTitle('Informasi Pengobatan'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _buildListItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Periode Pengobatan',
                        onTap: () => context.push('/profile/treatment-periods'),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildListItem(
                        icon: Icons.alarm,
                        title: 'Jadwal Minum Obat Harian',
                        onTap: () => context.push('/profile/medication-schedules'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Section 3: Lainnya
              _buildSectionTitle('Lainnya'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.logout_outlined,
                    color: AppColor.error,
                  ),
                  title: const Text(
                    'Keluar Akun',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColor.error,
                    ),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColor.darkGray,
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColor.darkGray),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColor.darkGray,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColor.neutralGray),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final nameCtrl = TextEditingController(text: viewModel.user?.name);
    final phoneCtrl = TextEditingController(
      text: viewModel.user?.telephoneNumber,
    );

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
              'Edit Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              controller: nameCtrl,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nomor Telepon',
              hint: 'Masukkan nomor telepon',
              controller: phoneCtrl,
              enabled: !viewModel.isLoading,
              keyboardType: TextInputType.phone,
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
                    text: 'Simpan',
                    height: 48,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      try {
                        await viewModel.updateUserProfile(
                          nameCtrl.text.trim(),
                          phoneCtrl.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil berhasil diperbarui'),
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

  void _showAddSupervisorDialog(
    BuildContext context,
    ProfileViewModel viewModel,
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
              'Tambah Pengawas',
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
              'Masukkan kode pengawas yang diberikan oleh PMO Anda untuk terhubung.',
              style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Kode Pengawas',
              hint: 'TBC-XXXXXX',
              controller: codeCtrl,
              enabled: !viewModel.isLoading,
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
                    text: 'Kirim',
                    height: 48,
                    isLoading: viewModel.isLoading,
                    onPressed: () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) return;
                      try {
                        await viewModel.addSupervisor(code);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Permintaan pengawasan berhasil dikirim'),
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

  void _showSupervisorDetailsDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final info = viewModel.supervisorInfo;
    if (info == null) return;

    AppDialog.info(
      context,
      title: 'Informasi Pengawas',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDialogInfoRow(label: 'Nama', value: info['name'] ?? '-'),
          AppDialogInfoRow(label: 'Telepon', value: info['telephone'] ?? '-'),
          AppDialogInfoRow(label: 'Kode', value: info['code'] ?? '-'),
          AppDialogInfoRow(
            label: 'Status',
            value: info['status'] ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showSupervisorCodeDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final code = viewModel.supervisorCode;

    AppDialog.info(
      context,
      title: 'Kode Pengawasan',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bagikan kode di bawah ini kepada pasien yang ingin Anda pantau.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColor.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary),
            ),
            child: Text(
              code ?? 'Belum ada kode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicationSchedulesDialog(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final scheds = viewModel.medicationSchedules;

    AppDialog.info(
      context,
      title: 'Jadwal Minum Obat',
      content: scheds.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Belum ada jadwal minum obat',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.neutralGray),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scheds.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = scheds[index];
                  final timeStr =
                      (item['schedule_time'] as String?)?.substring(0, 5) ??
                      '-';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm, color: AppColor.primary),
                    title: Text(item['med_name'] ?? '-'),
                    trailing: Text(
                      '$timeStr WIB',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext context) {
    AppDialog.confirm(
      context,
      title: 'Keluar Akun',
      message: 'Apakah Anda yakin ingin keluar dari akun ini?',
      confirmLabel: 'Keluar',
      confirmColor: AppButtonColor.danger,
      icon: Icons.logout,
      onConfirm: () async {
        await context.read<AuthViewModel>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      },
    );
  }
}
