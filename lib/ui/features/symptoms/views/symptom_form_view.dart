import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/symptom_model.dart';
import '../view_models/symptom_view_model.dart';

class SymptomFormView extends StatefulWidget {
  final SymptomViewModel viewModel;
  final SymptomLog? log;

  const SymptomFormView({super.key, required this.viewModel, this.log});

  @override
  State<SymptomFormView> createState() => _SymptomFormViewState();
}

class _SymptomFormViewState extends State<SymptomFormView> {
  late DateTime _selectedDate;
  late SymptomLevel _selectedLevel;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.log?.createdAt ?? DateTime.now();
    _selectedLevel = widget.log?.level ?? SymptomLevel.normal;
    _noteController = TextEditingController(text: widget.log?.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _resetForm() {
    if (widget.log != null) {
      setState(() {
        _selectedDate = widget.log!.createdAt;
        _selectedLevel = widget.log!.level;
        _noteController.text = widget.log!.note ?? '';
      });
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
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

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (widget.log == null) {
        await widget.viewModel.addLog(
          _selectedLevel,
          _noteController.text,
          createdAt: _selectedDate,
        );
      } else {
        final updatedLog = SymptomLog(
          id: widget.log!.id,
          treatmentPeriodId: widget.log!.treatmentPeriodId,
          level: _selectedLevel,
          note: _noteController.text,
          createdAt: _selectedDate,
          editedAt: DateTime.now(),
        );
        await widget.viewModel.updateLog(updatedLog);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.log != null;

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColor.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          isEdit ? 'Edit Catatan Gejala' : 'Tambah Catatan Gejala',
          style: const TextStyle(
            color: AppColor.darkGray,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanggal dan Waktu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColor.neutralGray.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(_selectedDate) +
                          ' WIB',
                      style: const TextStyle(color: AppColor.darkGray),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColor.neutralGray,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bagaimana kondisi Anda saat ini?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildConditionOption(
                  SymptomLevel.normal,
                  Icons.sentiment_satisfied_alt,
                ),
                const SizedBox(width: 12),
                _buildConditionOption(
                  SymptomLevel.mild,
                  Icons.sentiment_neutral,
                ),
                const SizedBox(width: 12),
                _buildConditionOption(
                  SymptomLevel.severe,
                  Icons.sentiment_very_dissatisfied,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Catatan Tambahan',
              hint: 'Ceritakan lebih detail mengenai apa yang Anda rasakan...',
              controller: _noteController,
              maxLines: 6,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.neutralGray.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColor.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Catatan akan langsung dapat dilihat oleh Pengawas Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.neutralGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (isEdit) ...[
                Expanded(
                  child: AppButton(
                    text: 'Reset',
                    variant: AppButtonVariant.outline,
                    height: 50,
                    onPressed: _resetForm,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: AppButton(
                  text: 'Simpan',
                  isLoading: _isSaving,
                  height: 50,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionOption(SymptomLevel level, IconData icon) {
    final isSelected = _selectedLevel == level;
    Color color;
    String label;

    switch (level) {
      case SymptomLevel.normal:
        color = AppColor.success;
        label = 'Normal';
        break;
      case SymptomLevel.mild:
        color = const Color(0xFFF09C15); // Warning/Orange
        label = 'Ringan';
        break;
      case SymptomLevel.severe:
        color = AppColor.error;
        label = 'Parah';
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColor.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColor.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColor.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
