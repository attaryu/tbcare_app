import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../data/models/treatment_period_model.dart';
import '../../../router/app_router.dart';
import '../view_models/treatment_view_model.dart';

class TreatmentView extends StatefulWidget {
  const TreatmentView({super.key});

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView> with RouteAware {

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
    context.read<TreatmentViewModel>().fetchTreatmentPeriods();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TreatmentViewModel>();

    return Scaffold(
      backgroundColor: AppColor.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.primary,
        shape: const CircleBorder(),
        onPressed: () =>
            context.push('/profile/treatment-periods/add', extra: viewModel),
        child: const Icon(Icons.add, color: AppColor.white, size: 28),
      ),
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
                  const Text(
                    'Periode Pengobatan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.darkGray,
                    ),
                  ),
                ],
              ),
            ),

            if (viewModel.isLoading &&
                viewModel.activePeriod == null &&
                viewModel.historyPeriods.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColor.primary),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => viewModel.fetchTreatmentPeriods(),
                  color: AppColor.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Periode Aktif
                        const Text(
                          'Periode Aktif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.darkGray,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (viewModel.activePeriod != null) ...[
                          _buildActivePeriodCard(
                            context,
                            viewModel.activePeriod!,
                            viewModel.compliancePercentage,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Edit Periode',
                                  variant: AppButtonVariant.outline,
                                  onPressed: () => context.push(
                                    '/profile/treatment-periods/edit',
                                    extra: {
                                      'viewModel': viewModel,
                                      'period': viewModel.activePeriod!,
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  text: 'Tandai Selesai',
                                  onPressed: () =>
                                      _confirmMarkCompleted(context, viewModel),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColor.lightGray,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 40,
                                  color: AppColor.neutralGray,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada periode pengobatan aktif.',
                                  style: TextStyle(
                                    color: AppColor.neutralGray,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  text: 'Buat Periode Baru',
                                  onPressed: () => context.push(
                                    '/profile/treatment-periods/add',
                                    extra: viewModel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Section 2: Riwayat Periode
                        const Text(
                          'Riwayat Periode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.darkGray,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (viewModel.historyPeriods.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColor.lightGray,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Belum ada riwayat periode pengobatan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.neutralGray,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: viewModel.historyPeriods.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildHistoryPeriodCard(
                                context,
                                viewModel.historyPeriods[index],
                              );
                            },
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePeriodCard(
    BuildContext context,
    TreatmentPeriodModel period,
    double percentage,
  ) {
    String dateRange = '-';
    try {
      final startStr = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(period.startDate);
      final endStr = period.predictionEndDate != null
          ? DateFormat(
              'dd MMMM yyyy',
              'id_ID',
            ).format(period.predictionEndDate!)
          : '-';
      dateRange = '$startStr - $endStr';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  period.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.white,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColor.white),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateRange,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentage / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 14, color: AppColor.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPeriodCard(
    BuildContext context,
    TreatmentPeriodModel period,
  ) {
    String dateRange = '-';
    try {
      final startStr = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(period.startDate);
      final endStr = period.actualEndDate != null
          ? DateFormat('dd MMMM yyyy', 'id_ID').format(period.actualEndDate!)
          : (period.predictionEndDate != null
                ? DateFormat(
                    'dd MMMM yyyy',
                    'id_ID',
                  ).format(period.predictionEndDate!)
                : '-');
      dateRange = '$startStr - $endStr';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  period.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColor.primary),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColor.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateRange,
                  style: const TextStyle(fontSize: 13, color: AppColor.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmMarkCompleted(
    BuildContext context,
    TreatmentViewModel viewModel,
  ) {
    AppDialog.confirm(
      context,
      title: 'Tandai Selesai',
      message: 'Apakah Anda yakin periode pengobatan ini telah selesai?',
      confirmLabel: 'Ya, Selesai',
      onConfirm: () async {
        try {
          await viewModel.markActivePeriodCompleted();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Periode pengobatan ditandai selesai!'),
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
        }
      },
    );
  }
}
