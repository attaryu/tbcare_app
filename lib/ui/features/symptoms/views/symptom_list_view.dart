import 'package:flutter/material.dart';
import '../../../../core/widgets/symptom_card.dart';
import '../view_models/symptom_view_model.dart';
import '../../../../data/models/symptom_model.dart';

class SymptomListView extends StatefulWidget {
  final SymptomViewModel viewModel;

  const SymptomListView({super.key, required this.viewModel});

  @override
  State<SymptomListView> createState() => _SymptomListViewState();
}

class _SymptomListViewState extends State<SymptomListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadLogs();
    });
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
            color: Colors.white,
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
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bagaimana kondisi Anda saat ini?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: SymptomLevel.values.map((level) {
                    final isSelected = selectedLevel == level;
                    Color color;
                    switch (level) {
                      case SymptomLevel.normal: color = Colors.green; break;
                      case SymptomLevel.mild: color = Colors.orange; break;
                      case SymptomLevel.severe: color = Colors.red; break;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedLevel = level),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              level.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade600,
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
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan detail gejala yang Anda rasakan...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Daftar Gejala',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => widget.viewModel.loadLogs(),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading && widget.viewModel.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.error != null && widget.viewModel.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Terjadi kesalahan: ${widget.viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.viewModel.loadLogs(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (widget.viewModel.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, 
                    size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada catatan gejala',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.viewModel.loadLogs,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: widget.viewModel.logs.length,
              itemBuilder: (context, index) {
                final log = widget.viewModel.logs[index];
                return SymptomCard(
                  log: log,
                  onDelete: () => _showDeleteConfirm(log),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSymptomDialog,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Gejala', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
