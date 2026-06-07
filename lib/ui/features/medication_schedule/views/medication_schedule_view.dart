import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../data/models/medication_schedule_model.dart';
import '../../../router/app_router.dart';
import '../view_models/medication_schedule_view_model.dart';

class MedicationScheduleView extends StatefulWidget {
  final MedicationScheduleViewModel viewModel;

  const MedicationScheduleView({super.key, required this.viewModel});

  @override
  State<MedicationScheduleView> createState() => _MedicationScheduleViewState();
}

class _MedicationScheduleViewState extends State<MedicationScheduleView> with RouteAware {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadSchedules();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    widget.viewModel.loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final period = widget.viewModel.activeTreatmentPeriod;
            final schedules = widget.viewModel.schedules;

            // Formatter tanggal
            String startDateStr = 'Mulai';
            String endDateStr = 'Selesai';
            if (period != null) {
              try {
                final st = DateTime.parse(period['start_date']);
                final ed = DateTime.parse(period['prediction_end_date']);
                startDateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(st);
                endDateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(ed);
              } catch (_) {}
            }

            return RefreshIndicator(
              onRefresh: () => widget.viewModel.loadSchedules(),
              color: AppColor.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                        const Text(
                          'Jadwal Minum Obat Harian',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColor.darkGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (widget.viewModel.isLoading && schedules.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColor.primary),
                        ),
                      )
                    else ...[
                      // Section Periode Jadwal
                      const Text(
                        'Periode Jadwal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Periode Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period?['name'] ?? 'Fase Intensif',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColor.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColor.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  period != null ? '$startDateStr - $endDateStr' : 'Belum ada periode aktif',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColor.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // List Jadwal
                      if (schedules.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.alarm_off, size: 48, color: AppColor.neutralGray),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada jadwal obat',
                                style: TextStyle(color: AppColor.neutralGray),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            final s = schedules[index];
                            final timeStr = s.scheduleTime.substring(0, 5);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColor.lightGray,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.medName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColor.darkGray,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: AppColor.neutralGray,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$timeStr WIB',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColor.neutralGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _showOptionsBottomSheet(context, s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColor.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.more_horiz,
                                        color: AppColor.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),

                      // Tambah Jadwal Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showAddEditBottomSheet(context),
                          child: const Text(
                            'Tambah Jadwal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(context),
        backgroundColor: AppColor.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColor.white, size: 28),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, MedicationScheduleModel s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColor.primary),
              title: const Text('Edit Jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showAddEditBottomSheet(context, existingSchedule: s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColor.error),
              title: const Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, s);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MedicationScheduleModel s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus jadwal obat "${s.medName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColor.neutralGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            onPressed: () async {
              try {
                await widget.viewModel.deleteSchedule(s.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jadwal berhasil dihapus'), backgroundColor: AppColor.success),
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
            child: const Text('Hapus', style: TextStyle(color: AppColor.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditBottomSheet(BuildContext context, {MedicationScheduleModel? existingSchedule}) {
    final medCtrl = TextEditingController(text: existingSchedule?.medName);
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    if (existingSchedule != null) {
      try {
        final parts = existingSchedule.scheduleTime.split(':');
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingSchedule == null ? 'Tambah Jadwal Minum Obat' : 'Edit Jadwal Minum Obat',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkGray,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColor.neutralGray),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Nama Obat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColor.darkGray)),
                const SizedBox(height: 8),
                TextField(
                  controller: medCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama obat (misal: Obat TBC - Rifampicin)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColor.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Waktu Minum Obat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColor.darkGray)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColor.darkGray),
                        ),
                        const Icon(Icons.access_time, color: AppColor.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (medCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama obat tidak boleh kosong'), backgroundColor: AppColor.error),
                        );
                        return;
                      }

                      final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                      try {
                        if (existingSchedule == null) {
                          await widget.viewModel.addSchedule(medCtrl.text.trim(), timeStr);
                        } else {
                          await widget.viewModel.updateSchedule(existingSchedule.id, medCtrl.text.trim(), timeStr);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existingSchedule == null ? 'Jadwal berhasil ditambahkan' : 'Jadwal berhasil diperbarui'),
                              backgroundColor: AppColor.success,
                            ),
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
                    child: Text(
                      existingSchedule == null ? 'Tambah Jadwal' : 'Simpan Perubahan',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
