import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class MedicationScheduleItem {
  String medName;
  TimeOfDay scheduleTime;

  MedicationScheduleItem(this.medName, this.scheduleTime);
}

class _RegisterViewState extends State<RegisterView>
    with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  String _selectedRole = 'pasien'; // default

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 Controllers
  final _supervisionCodeController = TextEditingController();

  // Step 3 Controllers
  final _treatmentNameController = TextEditingController();
  DateTime _treatmentStartDate = DateTime.now();
  final _treatmentDurationController = TextEditingController(text: '6');
  String _treatmentDurationType = 'month';

  // Step 4 Controllers
  final List<MedicationScheduleItem> _medicationSchedules = [
    MedicationScheduleItem(
      'Obat TBC - Isoniazid',
      const TimeOfDay(hour: 8, minute: 45),
    ),
    MedicationScheduleItem(
      'Obat TBC - Rifampicin',
      const TimeOfDay(hour: 12, minute: 10),
    ),
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _validationError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _supervisionCodeController.dispose();
    _treatmentNameController.dispose();
    _treatmentDurationController.dispose();
    super.dispose();
  }

  String _formatDateIndo(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime get _predictionEndDate {
    final int duration =
        int.tryParse(_treatmentDurationController.text.trim()) ?? 6;
    if (_treatmentDurationType == 'month') {
      return DateTime(
        _treatmentStartDate.year,
        _treatmentStartDate.month + duration,
        _treatmentStartDate.day,
      );
    } else {
      return _treatmentStartDate.add(Duration(days: duration));
    }
  }

  void _handlePrevious() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _validationError = null;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _handleNextOrSubmit() {
    if (_currentStep == 1) {
      _handleStep1Next();
    } else if (_currentStep == 2) {
      if (_selectedRole == 'pengawas') {
        _submitRegistration();
      } else {
        setState(() {
          _currentStep = 3;
          _validationError = null;
        });
        _fadeController.reset();
        _fadeController.forward();
      }
    } else if (_currentStep == 3) {
      _handleStep3Next();
    } else if (_currentStep == 4) {
      _submitRegistration();
    }
  }

  void _handleStep1Next() {
    HapticFeedback.lightImpact();
    setState(() {
      _validationError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() {
        _validationError = 'Mohon lengkapi semua kolom yang tersedia.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _validationError = 'Password minimal harus 8 karakter.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _validationError = 'Konfirmasi password tidak cocok.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = 2;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _handleStep3Next() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final title = _treatmentNameController.text.trim();
    final duration = int.tryParse(_treatmentDurationController.text.trim());

    if (title.isEmpty) {
      setState(() {
        _validationError = 'Mohon masukkan judul periode pengobatan.';
      });
      return;
    }

    if (duration == null || duration <= 0) {
      setState(() {
        _validationError = 'Mohon masukkan lama durasi pengobatan yang valid.';
      });
      return;
    }

    setState(() {
      _currentStep = 4;
      _validationError = null;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _submitRegistration() async {
    HapticFeedback.lightImpact();
    setState(() {
      _validationError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final supervisionCode = _supervisionCodeController.text.trim();

    final treatmentName = _treatmentNameController.text.trim();
    final duration =
        int.tryParse(_treatmentDurationController.text.trim()) ?? 6;

    final schedules = _medicationSchedules.map((item) {
      final hour = item.scheduleTime.hour.toString().padLeft(2, '0');
      final minute = item.scheduleTime.minute.toString().padLeft(2, '0');
      return {'med_name': item.medName, 'schedule_time': '$hour:$minute:00'};
    }).toList();

    FocusScope.of(context).unfocus();
    final authViewModel = context.read<AuthViewModel>();

    try {
      await authViewModel.register(
        name,
        email,
        phone,
        password,
        _selectedRole,
        supervisionCode: supervisionCode.isNotEmpty ? supervisionCode : null,
        treatmentName: _selectedRole == 'pasien'
            ? (treatmentName.isNotEmpty ? treatmentName : 'Periode Pengobatan')
            : null,
        startDate: _selectedRole == 'pasien' ? _treatmentStartDate : null,
        duration: _selectedRole == 'pasien' ? duration : null,
        durationType: _selectedRole == 'pasien' ? _treatmentDurationType : null,
        predictionEndDate: _selectedRole == 'pasien'
            ? _predictionEndDate
            : null,
        medicationSchedules: _selectedRole == 'pasien' ? schedules : null,
      );
      if (mounted && authViewModel.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil didaftarkan!'),
            backgroundColor: AppColor.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Error is caught and displayed via authViewModel.error
    }
  }

  void _showScheduleDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final item = isEdit ? _medicationSchedules[editIndex] : null;
    final nameCtrl = TextEditingController(text: item?.medName);
    TimeOfDay selectedTime = item?.scheduleTime ?? const TimeOfDay(hour: 8, minute: 0);

    AppDialog.custom(
      context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Jadwal Obat' : 'Tambah Jadwal Obat',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 20),
            _buildLabel('Nama Obat'),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
              decoration: _buildInputDecoration('Misal: Isoniazid'),
            ),
            const SizedBox(height: 20),
            _buildLabel('Waktu Minum'),
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColor.primary,
                        onPrimary: AppColor.white,
                        onSurface: AppColor.darkGray,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (time != null) {
                  setModalState(() => selectedTime = time);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColor.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColor.neutralGray.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGray,
                      ),
                    ),
                    const Icon(
                      Icons.access_time,
                      color: AppColor.primary,
                      size: 20,
                    ),
                  ],
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
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Simpan',
                    height: 48,
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          if (isEdit) {
                            _medicationSchedules[editIndex] = MedicationScheduleItem(
                              name,
                              selectedTime,
                            );
                          } else {
                            _medicationSchedules.add(
                              MedicationScheduleItem(name, selectedTime),
                            );
                          }
                        });
                        HapticFeedback.selectionClick();
                        Navigator.pop(dialogContext);
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColor.darkGray,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColor.neutralGray.withOpacity(0.6),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColor.lightGray.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColor.neutralGray.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.primary, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.primary
              : AppColor.primaryLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.primary,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.white.withOpacity(0.2)
                    : AppColor.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColor.white : AppColor.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColor.white : AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isSelected
                          ? AppColor.white.withOpacity(0.9)
                          : AppColor.primary.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Daftar Akun Baru',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColor.darkGray,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lengkapi data diri Anda untuk memulai perjalanan kesehatan bersama TBCare.',
          style: TextStyle(
            fontSize: 14,
            color: AppColor.neutralGray,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 36),

        // Input Nama Lengkap
        _buildLabel('Nama Lengkap'),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration('Masukkan nama lengkap Anda'),
        ),
        const SizedBox(height: 20),

        // Input Email
        _buildLabel('Email'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration('Masukkan email aktif'),
        ),
        const SizedBox(height: 20),

        // Input Nomor Telepon
        _buildLabel('Nomor Telepon'),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration('Masukkan nomor telepon aktif'),
        ),
        const SizedBox(height: 20),

        // Input Password
        _buildLabel('Password'),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration(
            'Buat password (minimal 8 karakter)',
            suffixIcon: IconButton(
              splashRadius: 24,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(_obscurePassword),
                  color: AppColor.neutralGray,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Input Konfirmasi Password
        _buildLabel('Konfirmasi Password'),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleStep1Next(),
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration(
            'Ketik ulang password Anda',
            suffixIcon: IconButton(
              splashRadius: 24,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(_obscureConfirmPassword),
                  color: AppColor.neutralGray,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pemilihan Peran',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColor.darkGray,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih peran Anda dalam sistem pemantauan.',
          style: TextStyle(
            fontSize: 14,
            color: AppColor.neutralGray,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 36),

        // Role Card: Pasien
        _buildRoleCard(
          title: 'Saya Pasien',
          subtitle: 'Saya sedang menjalani masa pengobatan TBC.',
          icon: Icons.health_and_safety_outlined,
          isSelected: _selectedRole == 'pasien',
          onTap: () => setState(() => _selectedRole = 'pasien'),
        ),
        const SizedBox(height: 20),

        // Role Card: Pengawas
        _buildRoleCard(
          title: 'Saya Pengawas',
          subtitle: 'Saya mendampingi dan memantau pengobatan pasien.',
          icon: Icons.shield_outlined,
          isSelected: _selectedRole == 'pengawas',
          onTap: () => setState(() => _selectedRole = 'pengawas'),
        ),
        const SizedBox(height: 36),

        // Sub-bagian dinamis berdasarkan role yang dipilih
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedRole == 'pengawas'
              ? Container(
                  key: const ValueKey('pengawas_info'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColor.neutralGray.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: AppColor.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Setelah pendaftaran berhasil, Anda akan mendapatkan Kode Pengawas unik untuk dibagikan kepada pasien yang Anda pantau.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColor.darkGray,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('pasien_input'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Kode Pengawas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _supervisionCodeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColor.darkGray,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode unik dari pengawas Anda',
                        hintStyle: TextStyle(
                          color: AppColor.neutralGray.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColor.lightGray.withOpacity(0.4),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColor.neutralGray.withOpacity(0.25),
                          ),
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
                    const SizedBox(height: 8),
                    const Text(
                      'Jika Anda belum memiliki kode, bagian ini bisa dilewati dan diisi nanti.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColor.neutralGray,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep3Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Buat Periode Penyembuhan',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColor.darkGray,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Periode penyembuhan TBC penting untuk dilacak demi kesehatan Anda',
          style: TextStyle(
            fontSize: 14,
            color: AppColor.neutralGray,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 36),

        // Input Judul
        _buildLabel('Judul'),
        TextFormField(
          controller: _treatmentNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
          decoration: _buildInputDecoration('Masukkan judul periode'),
        ),
        const SizedBox(height: 20),

        // Input Tanggal Mulai
        _buildLabel('Tanggal Mulai'),
        GestureDetector(
          onTap: () async {
            HapticFeedback.selectionClick();
            final picked = await showDatePicker(
              context: context,
              initialDate: _treatmentStartDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColor.primary,
                      onPrimary: AppColor.white,
                      onSurface: AppColor.darkGray,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _treatmentStartDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.neutralGray.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateIndo(_treatmentStartDate),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColor.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColor.neutralGray.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Input Lama Durasi & Satuan Waktu
        _buildLabel('Lama Durasi'),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _treatmentDurationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 15, color: AppColor.darkGray),
                onChanged: (_) => setState(() {}),
                decoration: _buildInputDecoration('Masukkan durasi pengobatan'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColor.neutralGray.withOpacity(0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _treatmentDurationType,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColor.neutralGray.withOpacity(0.8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'month',
                        child: Text(
                          'Bulan',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColor.darkGray,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'day',
                        child: Text(
                          'Hari',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColor.darkGray,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _treatmentDurationType = val);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Prediksi Berakhir (Read Only)
        _buildLabel('Prediksi Berakhir'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColor.lightGray.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.neutralGray.withOpacity(0.2)),
          ),
          child: Text(
            _formatDateIndo(_predictionEndDate),
            style: TextStyle(
              fontSize: 15,
              color: AppColor.darkGray.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep4Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Buat Jadwal Minum Obat',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColor.darkGray,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jadwal minum obat sangat penting bagi keberlangsungan pengobatan anda',
          style: TextStyle(
            fontSize: 14,
            color: AppColor.neutralGray,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 36),

        // Tombol Tambah Jadwal
        AppButton(text: 'Tambah Jadwal', onPressed: () => _showScheduleDialog()),
        const SizedBox(height: 28),

        // Daftar Jadwal
        if (_medicationSchedules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'Belum ada jadwal obat yang ditambahkan.',
                style: TextStyle(
                  color: AppColor.neutralGray.withOpacity(0.8),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _medicationSchedules.length,
            itemBuilder: (context, index) {
              final item = _medicationSchedules[index];
              final hour = item.scheduleTime.hour.toString().padLeft(2, '0');
              final minute = item.scheduleTime.minute.toString().padLeft(
                2,
                '0',
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColor.neutralGray.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.darkGray.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.medName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColor.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time_outlined,
                      size: 18,
                      color: AppColor.darkGray.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$hour:$minute WIB',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.darkGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: AppColor.white,
                          size: 20,
                        ),
                      ),
                      offset: const Offset(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showScheduleDialog(editIndex: index);
                        } else if (action == 'delete') {
                          setState(() {
                            _medicationSchedules.removeAt(index);
                          });
                          HapticFeedback.lightImpact();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColor.darkGray,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Edit Waktu',
                                style: TextStyle(
                                  color: AppColor.darkGray,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColor.error,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Hapus Jadwal',
                                style: TextStyle(
                                  color: AppColor.error,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final errorMessage = _validationError ?? authViewModel.error;
    final mediaQuery = MediaQuery.of(context);
    final totalMinHeight =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        72;

    Widget formContent;
    if (_currentStep == 1) {
      formContent = _buildStep1Form();
    } else if (_currentStep == 2) {
      formContent = _buildStep2Form();
    } else if (_currentStep == 3) {
      formContent = _buildStep3Form();
    } else {
      formContent = _buildStep4Form();
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 36.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: totalMinHeight > 0 ? totalMinHeight : 600,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Utama Dinamis
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_currentStep),
                      child: formContent,
                    ),
                  ),

                  // Bagian Bawah: Pesan Error & Tombol Navigasi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: errorMessage != null
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColor.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColor.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                            color: AppColor.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Tombol Dinamis
                      if (_currentStep == 1) ...[
                        AppButton(
                          text: 'Selanjutnya',
                          onPressed: _handleStep1Next,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                color: AppColor.darkGray,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.go('/login');
                              },
                              child: const Text(
                                'Masuk di sini',
                                style: TextStyle(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Sebelumnya',
                                variant: AppButtonVariant.outline,
                                isDisabled: authViewModel.isLoading,
                                onPressed: _handlePrevious,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                text: 'Selanjutnya',
                                isLoading: authViewModel.isLoading,
                                onPressed: _handleNextOrSubmit,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
