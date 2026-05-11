import 'package:flutter/material.dart';
import '../../../../data/models/symptom_model.dart';
import '../../../../data/repositories/symptom_repository.dart';

class SymptomViewModel extends ChangeNotifier {
  final SymptomRepository _repository;
  final int treatmentPeriodId;

  SymptomViewModel({
    required SymptomRepository repository,
    required this.treatmentPeriodId,
  }) : _repository = repository;

  List<SymptomLog> _logs = [];
  List<SymptomLog> get logs => _logs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logs = await _repository.getSymptomLogs(treatmentPeriodId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLog(SymptomLevel level, String? note) async {
    final log = SymptomLog(
      id: 0, // Database will generate
      treatmentPeriodId: treatmentPeriodId,
      level: level,
      note: note,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addSymptomLog(log);
      await loadLogs();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _repository.deleteSymptomLog(id);
      _logs.removeWhere((log) => log.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
