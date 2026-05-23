import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/treatment_period_model.dart';
import '../view_models/treatment_view_model.dart';

class TreatmentFormView extends StatefulWidget {
  final TreatmentViewModel viewModel;
  final TreatmentPeriodModel? existingPeriod;

  const TreatmentFormView({
    super.key,
    required this.viewModel,
    this.existingPeriod,
  });

  @override
  State<TreatmentFormView> createState() => _TreatmentFormViewState();
}

class _TreatmentFormViewState extends State<TreatmentFormView> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;
  late DateTime _startDate;
  late String _durationUnit;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingPeriod != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingPeriod?.name ?? '');
    _durationCtrl = TextEditingController(
      text: widget.existingPeriod?.duration.toString() ?? '',
    );
    _startDate = widget.existingPeriod?.startDate ?? DateTime.now();
    _durationUnit = widget.existingPeriod?.durationType ?? 'month';

    _durationCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  DateTime get _calculatedPrediction {
    final dur = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (_durationUnit == 'month') {
      return DateTime(_startDate.year, _startDate.month + dur, _startDate.day);
    } else {
      return _startDate.add(Duration(days: dur));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColor.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Edit Periode Penyembuhan'
                          : 'Buat Periode Penyembuhan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Judul',
                      hint: 'Masukkan judul periode',
                      controller: _titleCtrl,
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Tanggal Mulai'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isEditing
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _isEditing
                              ? AppColor.lightGray
                              : AppColor.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_startDate),
                              style: TextStyle(
                                fontSize: 15,
                                color: _isEditing
                                    ? AppColor.neutralGray
                                    : AppColor.darkGray,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              color: _isEditing
                                  ? AppColor.neutralGray
                                  : AppColor.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          '*Tanggal mulai tidak dapat diubah saat mengedit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColor.neutralGray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    _buildLabel('Lama Durasi'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            controller: _durationCtrl,
                            hint: 'Masukkan durasi pengobatan',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            enabled: !_isSubmitting,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _durationUnit,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColor.neutralGray,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'month',
                                    child: Text('Bulan'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'day',
                                    child: Text('Hari'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _durationUnit = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Prediksi Berakhir'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.lightGray,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(_calculatedPrediction),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColor.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    AppButton(
                      text: _isEditing ? 'Simpan Perubahan' : 'Buat',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColor.darkGray,
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;

    if (title.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi judul dan lama durasi dengan valid'),
          backgroundColor: AppColor.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing) {
        await widget.viewModel.updatePeriod(
          widget.existingPeriod!.id,
          title,
          _startDate,
          duration,
          _durationUnit,
        );
      } else {
        await widget.viewModel.createNewPeriod(
          title,
          _startDate,
          duration,
          _durationUnit,
        );
      }

      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Periode pengobatan berhasil diperbarui!'
                  : 'Periode baru berhasil dibuat!',
            ),
            backgroundColor: AppColor.success,
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
