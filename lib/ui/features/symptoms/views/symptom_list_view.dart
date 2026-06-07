import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/symptom_card.dart';
import '../../../../data/models/symptom_model.dart';
import '../view_models/symptom_view_model.dart';

class SymptomListView extends StatefulWidget {
  final SymptomViewModel viewModel;

  const SymptomListView({super.key, required this.viewModel});

  @override
  State<SymptomListView> createState() => _SymptomListViewState();
}

class _SymptomListViewState extends State<SymptomListView> {
  String _searchQuery = '';
  SymptomLevel? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadLogs();
    });
  }

  List<SymptomLog> get _filteredLogs {
    return widget.viewModel.logs.where((log) {
      final matchesSearch =
          log.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
      final matchesFilter =
          _selectedFilter == null || log.level == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final logs = _filteredLogs;

            return RefreshIndicator(
              onRefresh: widget.viewModel.loadLogs,
              child: CustomScrollView(
                slivers: [
                  // Judul
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Riwayat Gejala',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.darkGray,
                        ),
                      ),
                    ),
                  ),

                  // Sticky Header (Search Bar + Centered Chips Filter)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColor.lightGray.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColor.neutralGray.withOpacity(0.3),
                                ),
                              ),
                              child: TextField(
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                decoration: const InputDecoration(
                                  hintText: 'Cari catatan gejala...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColor.neutralGray,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Centered Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFilterChip(null, 'Semua'),
                                _buildFilterChip(SymptomLevel.normal, 'Normal'),
                                _buildFilterChip(SymptomLevel.mild, 'Ringan'),
                                _buildFilterChip(SymptomLevel.severe, 'Parah'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content List
                  if (widget.viewModel.isLoading &&
                      widget.viewModel.logs.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
                      ),
                    )
                  else if (logs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 80,
                              color: AppColor.neutralGray,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada catatan gejala',
                              style: TextStyle(color: AppColor.neutralGray),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16, bottom: 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final log = logs[index];
                          return SymptomCard(
                            log: log,
                            onDelete: () => _showDeleteConfirm(log),
                            onTap: () => _showSymptomDetailModal(
                              context,
                              log,
                              widget.viewModel,
                            ),
                          );
                        }, childCount: logs.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/symptoms/add', extra: widget.viewModel),
        backgroundColor: AppColor.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColor.white, size: 32),
      ),
    );
  }

  Widget _buildFilterChip(SymptomLevel? level, String label) {
    final isSelected = _selectedFilter == level;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? level : null);
        },
        backgroundColor: const Color(0xFFE6F8F3),
        selectedColor: AppColor.primary,
        checkmarkColor: AppColor.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColor.white : AppColor.primary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? AppColor.primary : const Color(0xFFA0E4CB),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  void _showDeleteConfirm(SymptomLog log) {
    AppDialog.confirm(
      context,
      title: 'Hapus Catatan',
      message: 'Apakah Anda yakin ingin menghapus catatan gejala ini?',
      confirmLabel: 'Hapus',
      confirmColor: AppButtonColor.danger,
      icon: Icons.delete_outline,
      onConfirm: () {
        widget.viewModel.deleteLog(log.id);
      },
    );
  }

  void _showSymptomDetailModal(
    BuildContext context,
    SymptomLog log,
    SymptomViewModel viewModel,
  ) {
    Color levelColor = AppColor.success;
    if (log.level == SymptomLevel.mild) levelColor = const Color(0xFFF09C15);
    if (log.level == SymptomLevel.severe) levelColor = AppColor.error;

    AppDialog.custom(
      context,
      barrierDismissible: true,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Riwayat Gejala',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColor.neutralGray),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Tingkat Gejala: ',
                style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  log.level.displayName,
                  style: const TextStyle(
                    color: AppColor.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColor.neutralGray,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat(
                  'dd MMMM yyyy, HH:mm',
                  'id_ID',
                ).format(log.createdAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Catatan / Keluhan:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColor.darkGray,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              log.note ?? 'Tidak ada deskripsi keluhan.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.darkGray,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Hapus',
                  variant: AppButtonVariant.outline,
                  color: AppButtonColor.danger,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirm(log);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppButton(
                  text: 'Edit Catatan',
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.push(
                      '/symptoms/edit',
                      extra: {'viewModel': viewModel, 'log': log},
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColor.white, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
