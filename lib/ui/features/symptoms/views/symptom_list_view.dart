import 'package:flutter/material.dart';
import '../../../../core/widgets/symptom_card.dart';
import '../view_models/symptom_view_model.dart';
import '../../../../data/models/symptom_model.dart';
import '../../../../core/theme/app_color.dart';

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
      final matchesSearch = log.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
      final matchesFilter = _selectedFilter == null || log.level == _selectedFilter;
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
                  border: Border.all(color: AppColor.neutralGray.withOpacity(0.3)),
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
                  if (widget.viewModel.isLoading && widget.viewModel.logs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = _filteredLogs;

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, 
                            size: 80, color: AppColor.lightGray),
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
        onPressed: _showAddSymptomDialog,
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

  void _showAddSymptomDialog() {
    SymptomLevel selectedLevel = SymptomLevel.normal;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catat Gejala',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.darkGray,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bagaimana kondisi Anda saat ini?',
                  style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: SymptomLevel.values.map((level) {
                    final isSelected = selectedLevel == level;
                    Color color;
                    switch (level) {
                      case SymptomLevel.normal: color = AppColor.success; break;
                      case SymptomLevel.mild: color = AppColor.warning; break;
                      case SymptomLevel.severe: color = AppColor.error; break;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedLevel = level),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color : AppColor.lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              level.displayName,
                              style: TextStyle(
                                color: isSelected ? AppColor.white : AppColor.neutralGray,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Catatan tambahan (opsional)',
                  style: TextStyle(fontSize: 14, color: AppColor.neutralGray),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan detail gejala yang Anda rasakan...',
                    filled: true,
                    fillColor: AppColor.lightGray.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await widget.viewModel.addLog(
                          selectedLevel,
                          noteController.text,
                        );
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Simpan Gejala',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(SymptomLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan gejala ini?'),
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
