import 'package:flutter/material.dart';
import '../../../../data/models/medication_schedule_model.dart';
import '../../../../data/repositories/medication_schedule_repository.dart';

class MedicationScheduleViewModel extends ChangeNotifier {
  final MedicationScheduleRepository _repository;
  final int _userId;

  MedicationScheduleViewModel({
    required MedicationScheduleRepository repository,
    required int userId,
  })  : _repository = repository,
        _userId = userId {
    loadSchedules();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _activeTreatmentPeriod;
  Map<String, dynamic>? get activeTreatmentPeriod => _activeTreatmentPeriod;

  List<MedicationScheduleModel> _schedules = [];
  List<MedicationScheduleModel> get schedules => _schedules;

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final period = await _repository.getActiveTreatmentPeriod(_userId);
      _activeTreatmentPeriod = period;

      if (period != null) {
        final tpId = period['id'] as int;
        _schedules = await _repository.getMedicationSchedules(tpId);
      } else {
        _schedules = [];
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSchedule(String medName, String scheduleTime) async {
    if (_activeTreatmentPeriod == null) {
      throw Exception('Tidak ada periode pengobatan aktif. Harap buat periode pengobatan terlebih dahulu.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final tpId = _activeTreatmentPeriod!['id'] as int;
      final schedule = MedicationScheduleModel(
        id: 0,
        treatmentPeriodId: tpId,
        medName: medName,
        scheduleTime: scheduleTime,
      );
      await _repository.addMedicationSchedule(schedule);
      await loadSchedules();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSchedule(int id, String medName, String scheduleTime) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateMedicationSchedule(id, medName, scheduleTime);
      await loadSchedules();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSchedule(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteMedicationSchedule(id);
      await loadSchedules();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
