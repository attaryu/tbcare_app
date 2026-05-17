import 'package:flutter/material.dart';
import '../../../../data/models/treatment_period_model.dart';
import '../../../../data/repositories/treatment_repository.dart';

class TreatmentViewModel extends ChangeNotifier {
  final TreatmentRepository _repository;
  final int _userId;

  TreatmentViewModel({required TreatmentRepository repository, required int userId})
      : _repository = repository,
        _userId = userId {
    fetchTreatmentPeriods();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  TreatmentPeriodModel? _activePeriod;
  TreatmentPeriodModel? get activePeriod => _activePeriod;

  List<TreatmentPeriodModel> _historyPeriods = [];
  List<TreatmentPeriodModel> get historyPeriods => _historyPeriods;

  double _compliancePercentage = 0.0;
  double get compliancePercentage => _compliancePercentage;

  Future<void> fetchTreatmentPeriods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _repository.getTreatmentPeriods(_userId);
      _activePeriod = null;
      _historyPeriods = [];

      for (var item in list) {
        if (item.status == 'active') {
          _activePeriod = item;
        } else {
          _historyPeriods.add(item);
        }
      }

      if (_activePeriod != null) {
        _compliancePercentage = await _repository.getCompliancePercentage(_activePeriod!.id);
      } else {
        _compliancePercentage = 0.0;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markActivePeriodCompleted() async {
    if (_activePeriod == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.markPeriodCompleted(_activePeriod!.id);
      await fetchTreatmentPeriods();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createNewPeriod(
    String name,
    DateTime startDate,
    int duration,
    String durationType,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      DateTime predictionEndDate;
      if (durationType == 'month') {
        predictionEndDate = DateTime(startDate.year, startDate.month + duration, startDate.day);
      } else {
        predictionEndDate = startDate.add(Duration(days: duration));
      }

      await _repository.createTreatmentPeriod(_userId, name, startDate, predictionEndDate, duration, durationType);
      await fetchTreatmentPeriods();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePeriod(
    int periodId,
    String name,
    DateTime startDate,
    int duration,
    String durationType,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      DateTime predictionEndDate;
      if (durationType == 'month') {
        predictionEndDate = DateTime(startDate.year, startDate.month + duration, startDate.day);
      } else {
        predictionEndDate = startDate.add(Duration(days: duration));
      }

      await _repository.updateTreatmentPeriod(periodId, name, duration, durationType, predictionEndDate);
      await fetchTreatmentPeriods();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
