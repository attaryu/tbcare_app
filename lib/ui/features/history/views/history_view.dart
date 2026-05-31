import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_medication_schedule_card.dart';
import '../view_models/history_view_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();

    if (viewModel.isLoading && viewModel.activeTreatment == null) {
      return const Scaffold(
        backgroundColor: AppColor.lightGray,
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    final activeTp = viewModel.activeTreatment;
    String startDateStr = '-';
    String endDateStr = '-';

    if (activeTp != null) {
      try {
        final st = DateTime.parse(activeTp['start_date']);
        final ed = DateTime.parse(activeTp['prediction_end_date']);
        startDateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(st);
        endDateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(ed);
      } catch (_) {}
    }

    final stats = viewModel.stats;
    final percentage = stats['percentage'] as double;
    final daysInCurrentMonth = DateTime(viewModel.currentMonth.year, viewModel.currentMonth.month + 1, 0).day;
    final currentDayOrMax = DateTime.now().month == viewModel.currentMonth.month
        ? DateTime.now().day
        : daysInCurrentMonth;

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
                'Riwayat Pengobatan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 20),

              // Active Treatment Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode: ${activeTp?['name'] ?? "Fase Intensif"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColor.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColor.neutralGray),
                        const SizedBox(width: 8),
                        Text(
                          '$startDateStr - $endDateStr',
                          style: const TextStyle(fontSize: 13, color: AppColor.neutralGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Laporan Pengobatan Bulan Ini
              const Text(
                'Laporan Pengobatan Bulan Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 12),

              // Persentase Kepatuhan Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA0E4CB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Persentase Kepatuhan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColor.primary),
                        ),
                        Text(
                          '$currentDayOrMax/$daysInCurrentMonth Hari',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage / 100.0,
                        minHeight: 10,
                        backgroundColor: AppColor.primary.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grid 4 Statistik
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      title: 'Terverifikasi',
                      count: stats['terverifikasi'],
                      iconColor: AppColor.success,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pan_tool_outlined,
                      title: 'Tidak terverifikasi',
                      count: stats['tidakTerverifikasi'],
                      iconColor: AppColor.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.sentiment_dissatisfied_outlined,
                      title: 'Terlambat',
                      count: stats['terlambat'],
                      iconColor: AppColor.warning,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.close,
                      title: 'Terlewat',
                      count: stats['terlewat'],
                      iconColor: AppColor.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Kalender Komponen
              _buildCalendarCard(context, viewModel),
              const SizedBox(height: 32),

              // Jadwal Tanggal Terpilih
              Text(
                DateFormat('d MMMM yyyy', 'id_ID').format(viewModel.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              const SizedBox(height: 12),

              _buildSelectedDateSchedules(context, viewModel),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required int count, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F8F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA0E4CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, HistoryViewModel viewModel) {
    final currentMonth = viewModel.currentMonth;
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(currentMonth.year, currentMonth.month, 1).weekday % 7;

    final weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA0E4CB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(currentMonth),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.darkGray),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                    child: IconButton(
                      iconSize: 18,
                      icon: const Icon(Icons.chevron_left, color: AppColor.darkGray),
                      onPressed: viewModel.previousMonth,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                    child: IconButton(
                      iconSize: 18,
                      icon: const Icon(Icons.chevron_right, color: AppColor.darkGray),
                      onPressed: viewModel.nextMonth,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Header Hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((w) => SizedBox(
                      width: 36,
                      child: Text(
                        w,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.darkGray),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Grid Tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: firstDayOfWeek + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek) return const SizedBox.shrink();

              final dayNum = index - firstDayOfWeek + 1;
              final dayDate = DateTime(currentMonth.year, currentMonth.month, dayNum);
              final status = viewModel.getDayStatus(dayDate);
              final isSelected = dayDate.year == viewModel.selectedDate.year &&
                  dayDate.month == viewModel.selectedDate.month &&
                  dayDate.day == viewModel.selectedDate.day;

              Color bg = const Color(0xFFE9ECEF);
              Color textColor = AppColor.darkGray;
              if (status == 'Penuh') {
                bg = AppColor.success;
                textColor = AppColor.white;
              } else if (status == 'Sebagian') {
                bg = const Color(0xFFF0A500);
                textColor = AppColor.white;
              } else if (status == 'Terlewat') {
                bg = AppColor.error;
                textColor = AppColor.white;
              }

              return InkWell(
                onTap: () => viewModel.selectDate(dayDate),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: AppColor.darkGray, width: 2.5) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNum.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(AppColor.success, 'Penuh'),
              _buildLegendItem(const Color(0xFFF0A500), 'Sebagian'),
              _buildLegendItem(AppColor.error, 'Terlewat'),
              _buildLegendItem(const Color(0xFFE9ECEF), 'Mendatang', isBorder: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColor.darkGray, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSelectedDateSchedules(BuildContext context, HistoryViewModel viewModel) {
    final items = viewModel.getSchedulesForSelectedDate();

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColor.lightGray, borderRadius: BorderRadius.circular(16)),
        child: const Text(
          'Tidak ada jadwal obat pada tanggal ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColor.neutralGray, fontSize: 14),
        ),
      );
    }

    final activeIds = viewModel.activeScheduleIds;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'] as int;
        final name = item['med_name'] as String;
        final timeStr = item['schedule_time'] as String;
        final status = item['status'] as String;
        final isVerified = item['is_verified'] as bool? ?? false;
        final isActive = activeIds.contains(id);

        return AppMedicationScheduleCard(
          medName: name,
          scheduleTime: timeStr,
          status: status,
          isVerified: isVerified,
          isActive: isActive,
          onTap: () => viewModel.toggleLogStatus(id, status),
        );
      },
    );
  }
}
