import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
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
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Cari catatan gejala...',
                    prefixIcon: Icon(Icons.search, color: AppColor.neutralGray),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(null, 'Semua'),
                  _buildFilterChip(SymptomLevel.normal, 'Normal'),
                  _buildFilterChip(SymptomLevel.mild, 'Ringan'),
                  _buildFilterChip(SymptomLevel.severe, 'Parah'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.isLoading &&
                      widget.viewModel.logs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = _filteredLogs;

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 80,
                            color: AppColor.lightGray,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada catatan gejala',
                            style: TextStyle(color: AppColor.neutralGray),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: widget.viewModel.loadLogs,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return SymptomCard(
                          log: logs[index],
                          onDelete: () => _showDeleteConfirm(logs[index]),
                          onTap: () => context.push(
                            '/symptoms/edit',
                            extra: {
                              'viewModel': widget.viewModel,
                              'log': logs[index],
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? level : null);
        },
        backgroundColor: AppColor.white,
        selectedColor: AppColor.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColor.white : AppColor.primary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColor.primary.withOpacity(0.5)),
        ),
        showCheckmark: false,
      ),
    );
  }

  void _showDeleteConfirm(SymptomLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus catatan gejala ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.viewModel.deleteLog(log.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColor.error)),
          ),
        ],
      ),
    );
  }
}
