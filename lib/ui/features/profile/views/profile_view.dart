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

              // Dynamic Menu Sections
              for (var section in viewModel.menuSections) ...[
                _buildSectionTitle(section.title),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: section.items.any((item) => item.isDestructive)
                        ? const Color(0xFFFFF0F0)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: section.items.any((item) => item.isDestructive)
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < section.items.length; i++) ...[
                        _buildListItem(
                          icon: section.items[i].icon,
                          title: section.items[i].title,
                          isDestructive: section.items[i].isDestructive,
                          onTap: () => _handleMenuTap(context, viewModel, section.items[i].action),
                        ),
                        if (i < section.items.length - 1)
                          Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
              const SizedBox(height: 12),
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
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: isDestructive ? AppColor.error : AppColor.darkGray),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
          color: isDestructive ? AppColor.error : AppColor.darkGray,
        ),
      ),
      trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: AppColor.neutralGray),
      onTap: onTap,
    );
  }

  void _handleMenuTap(
    BuildContext context,
    ProfileViewModel viewModel,
    ProfileMenuAction action,
  ) {
    switch (action) {
      case ProfileMenuAction.editProfile:
        _showEditProfileDialog(context, viewModel);
        break;
      case ProfileMenuAction.viewSupervisor:
        _showSupervisorDetailsDialog(context, viewModel);
        break;
      case ProfileMenuAction.addSupervisor:
        _showAddSupervisorDialog(context, viewModel);
        break;
      case ProfileMenuAction.treatmentPeriod:
        context.push('/profile/treatment-periods');
        break;
      case ProfileMenuAction.medicationSchedule:
        context.push('/profile/medication-schedules');
        break;
      case ProfileMenuAction.logout:
        _confirmLogout(context);
        break;
    }
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
