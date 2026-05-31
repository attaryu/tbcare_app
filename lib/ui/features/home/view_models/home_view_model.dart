import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/home_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final int _userId;

  HomeViewModel({required HomeRepository repository, required int userId})
      : _repository = repository,
        _userId = userId {
    fetchHomeData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  UserModel? _user;
  UserModel? get user => _user;

  bool _hasSupervisor = false;
  bool get hasSupervisor => _hasSupervisor;

  Map<String, dynamic>? _supervisorInfo;
  Map<String, dynamic>? get supervisorInfo => _supervisorInfo;

  Map<String, dynamic>? _activeTreatment;
  Map<String, dynamic>? get activeTreatment => _activeTreatment;

  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> get schedules => _schedules;

  double _complianceRate = 98.0;
  double get complianceRate => _complianceRate;

  int _daysPassed = 50;
  int get daysPassed => _daysPassed;

  bool _isAlarmTriggering = false;
  bool get isAlarmTriggering => _isAlarmTriggering;

  bool _isWithin30MinsSimulation = true;
  bool get isWithin30MinsSimulation => _isWithin30MinsSimulation;

  Map<String, dynamic>? get nextSchedule {
    if (_schedules.isEmpty) return null;

    final now = DateTime.now();
    final todayPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Hanya jadwal yang belum diminum
    final pending = _schedules
        .where((s) => s['today_status'] != 'Di minum')
        .toList();

    if (pending.isEmpty) return null;

    // Cari jadwal dengan waktu paling dekat dari sekarang
    Map<String, dynamic>? closest;
    Duration? closestDiff;

    for (final s in pending) {
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null) continue;
      final timePart = timeStr.substring(0, 5); // "HH:mm"
      final schedDateTime = DateTime.tryParse('${todayPrefix}T$timePart:00');
      if (schedDateTime == null) continue;

      final diff = schedDateTime.difference(now).abs();
      if (closestDiff == null || diff < closestDiff) {
        closestDiff = diff;
        closest = s;
      }
    }

    return closest ?? pending.first;
  }

  void toggleAlarmSimulation() {
    _isAlarmTriggering = !_isAlarmTriggering;
    if (_isAlarmTriggering) {
      _isWithin30MinsSimulation = true;
    }
    notifyListeners();
  }

  void toggleWithin30MinsSimulation() {
    _isWithin30MinsSimulation = !_isWithin30MinsSimulation;
    if (!_isWithin30MinsSimulation) {
      _isAlarmTriggering = false;
    }
    notifyListeners();
  }

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getHomeData(_userId);
      _user = data['user'] as UserModel;
      _hasSupervisor = data['hasSupervisor'] as bool;
      _supervisorInfo = data['supervisorInfo'] as Map<String, dynamic>?;
      _activeTreatment = data['activeTreatment'] as Map<String, dynamic>?;
      _schedules = data['schedules'] as List<Map<String, dynamic>>;
      _complianceRate = data['complianceRate'] as double;
      _daysPassed = data['daysPassed'] as int;

      _isWithin30MinsSimulation = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectSupervisor(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.connectSupervisor(_userId, code);
      await fetchHomeData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> confirmMedicationTaken(int scheduleId, {String? photoUrl}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.logMedicationTaken(scheduleId, photoUrl: photoUrl);
      await fetchHomeData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void snoozeMedication() {
    _isAlarmTriggering = false;
    notifyListeners();
  }
}
