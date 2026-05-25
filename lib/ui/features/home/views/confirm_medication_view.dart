import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tbcare_app/core/theme/app_color.dart';
import 'package:tbcare_app/core/widgets/app_button.dart';
import '../view_models/confirm_medication_view_model.dart';

class ConfirmMedicationView extends StatelessWidget {
  const ConfirmMedicationView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConfirmMedicationViewModel>();

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (matching style of Medication Schedules view)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: viewModel.isLoading ? null : () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Konfirmasi Minum Obat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColor.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Medication Detail Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColor.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.primary, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.medName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.alarm,
                                size: 16,
                                color: AppColor.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Jadwal: ${viewModel.scheduleTime} WIB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.darkGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title section
                    const Text(
                      'Unggah Foto Bukti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ambil foto obat Anda saat hendak diminum sebagai bukti kepatuhan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo preview container
                    GestureDetector(
                      onTap: viewModel.isLoading
                          ? null
                          : () => _showPickerOptions(context, viewModel),
                      child: Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: AppColor.lightGray,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: viewModel.imageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    viewModel.imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.6),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: AppColor.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Ketuk untuk mengganti foto',
                                          style: TextStyle(
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Ketuk untuk Ambil Foto',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kamera atau Galeri',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Compression Simulation Stats Info if image selected
                    if (viewModel.imageFile != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1FDF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7F3E5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppColor.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Optimalisasi Penyimpanan Aktif',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColor.darkGray,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Foto akan dikompresi menjadi ukuran sangat kecil (~15-30 KB) untuk menghemat memori penyimpanan database.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Error display if any
                    if (viewModel.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          viewModel.error!,
                          style: const TextStyle(
                            color: AppColor.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (viewModel.showSimulationOption) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Gunakan Foto Simulasi',
                          variant: AppButtonVariant.outline,
                          onPressed: () => viewModel.useSimulatedPhoto(),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Submit Button Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: AppButton(
                text: 'Kirim Konfirmasi',
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.imageFile == null,
                onPressed: () => viewModel.submitConfirmation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions(BuildContext context, ConfirmMedicationViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    context: bottomSheetContext,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      viewModel.pickImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceButton(
                    context: bottomSheetContext,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      viewModel.pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColor.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColor.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColor.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
