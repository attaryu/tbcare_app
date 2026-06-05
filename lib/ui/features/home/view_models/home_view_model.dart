import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/home_repository.dart';
import '../../../router/app_router.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final int _userId;
  Timer? _timer;

  HomeViewModel({required HomeRepository repository, required int userId})
      : _repository = repository,
        _userId = userId {
    fetchHomeData();
    _startTimer();
    AppAlarmService.setAlarmRingCallback(_handleAlarmRing);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      autoMarkMissedSchedules();
      final oldVal = _isWithin30MinsSimulation;
      _isWithin30MinsSimulation = _checkIfWithin30Mins();
      if (oldVal != _isWithin30MinsSimulation) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppAlarmService.clearAlarmRingCallback();
    super.dispose();
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

  double _complianceRate = 0.0;
  double get complianceRate => _complianceRate;

  int _daysPassed = 0;
  int get daysPassed => _daysPassed;

  bool _isAlarmTriggering = false;
  bool get isAlarmTriggering => _isAlarmTriggering;

  bool _isWithin30MinsSimulation = false;
  bool get isWithin30MinsSimulation => _isWithin30MinsSimulation;

  List<Map<String, dynamic>> get nextSchedules {
    if (_schedules.isEmpty) return [];

    final now = DateTime.now();
    final todayPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Hanya jadwal yang berstatus Segera (akan datang dan belum lewat/diminum)
    final pending = _schedules
        .where((s) => s['today_status'] == 'Segera')
        .toList();

    if (pending.isEmpty) return [];

    // Cari jadwal dengan waktu paling dekat dari sekarang (selisih terkecil)
    Duration? minDiff;
    for (final s in pending) {
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null) continue;
      final timePart = timeStr.substring(0, 5); // "HH:mm"
      final schedDateTime = DateTime.tryParse('${todayPrefix}T$timePart:00');
      if (schedDateTime == null) continue;

      final diff = schedDateTime.difference(now).abs();
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
      }
    }

    if (minDiff == null) return [];

    // Ambil semua jadwal dari pending yang memiliki selisih waktu terdekat yang sama
    final closestSchedules = <Map<String, dynamic>>[];
    for (final s in pending) {
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null) continue;
      final timePart = timeStr.substring(0, 5);
      final schedDateTime = DateTime.tryParse('${todayPrefix}T$timePart:00');
      if (schedDateTime == null) continue;

      final diff = schedDateTime.difference(now).abs();
      if ((diff - minDiff).inSeconds.abs() == 0) {
        closestSchedules.add(s);
      }
    }

    return closestSchedules;
  }

  Map<String, dynamic>? get nextSchedule {
    final list = nextSchedules;
    return list.isNotEmpty ? list.first : null;
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
      _schedules = List<Map<String, dynamic>>.from(data['schedules'] as List);
      _schedules.sort((a, b) {
        final timeA = a['schedule_time'] as String? ?? '';
        final timeB = b['schedule_time'] as String? ?? '';
        return timeA.compareTo(timeB);
      });
      _complianceRate = data['complianceRate'] as double;
      _daysPassed = data['daysPassed'] as int;

      _isWithin30MinsSimulation = _checkIfWithin30Mins();
      _error = null;

      // Auto sync alarms to keep OS alarms perfectly up to date
      try {
        final syncData = List<Map<String, dynamic>>.from(data['schedules'] as List);
        await AppAlarmService.syncAlarmsWithSchedules(syncData);
      } catch (e) {
        debugPrint('Auto sync alarms on home load failed: $e');
      }

      // Panggil auto-mark setelah load
      await autoMarkMissedSchedules();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isTimePassed(String scheduleTimeStr) {
    try {
      final now = DateTime.now();
      final parts = scheduleTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final scheduleDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );

      return now.isAfter(scheduleDateTime);
    } catch (_) {
      return false;
    }
  }

  Future<void> autoMarkMissedSchedules() async {
    if (_schedules.isEmpty) return;

    bool hasChanges = false;
    for (final s in _schedules) {
      final status = s['today_status'] as String? ?? 'Segera';
      if (status == 'Segera') {
        final timeStr = s['schedule_time'] as String?;
        if (timeStr != null && _isTimePassed(timeStr)) {
          try {
            await _repository.upsertMissedLog(s['id'] as int, s['med_name'] as String? ?? 'Obat TBC');
            hasChanges = true;
          } catch (e) {
            debugPrint('Failed to auto-mark missed schedule ${s['id']}: $e');
          }
        }
      }
    }

    if (hasChanges) {
      // Refresh home data secara internal tanpa set loading flag untuk user experience yang seamless
      try {
        final data = await _repository.getHomeData(_userId);
        _schedules = List<Map<String, dynamic>>.from(data['schedules'] as List);
        _schedules.sort((a, b) {
          final timeA = a['schedule_time'] as String? ?? '';
          final timeB = b['schedule_time'] as String? ?? '';
          return timeA.compareTo(timeB);
        });
        _complianceRate = data['complianceRate'] as double;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to refresh home data after auto-mark: $e');
      }
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

  bool _checkIfWithin30Mins() {
    if (_schedules.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final s in _schedules) {
      if (s['today_status'] != 'Segera') continue;
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null || timeStr.isEmpty) continue;
      
      final timePart = timeStr.substring(0, 5);
      final schedTime = DateTime.tryParse('${todayStr}T$timePart:00');
      if (schedTime == null) continue;

      final diffInMinutes = schedTime.difference(now).inMinutes.abs();
      if (diffInMinutes <= 30) {
        return true;
      }
    }
    return false;
  }

  void _handleAlarmRing(AlarmSettings alarmSettings) {
    final alarmId = alarmSettings.id;
    debugPrint('HomeViewModel received alarm ring event: $alarmId');

    _isAlarmTriggering = true;
    _isWithin30MinsSimulation = true;
    notifyListeners();

    final scheduleId = alarmId == 999 ? 999 : alarmId ~/ 10;
    String medName = 'Obat TBC';
    String scheduleTime = '00:00';

    if (scheduleId == 999) {
      medName = 'Obat Test PoC';
      scheduleTime = DateTime.now().toIso8601String().substring(11, 16);
    } else {
      final schedule = _schedules.firstWhere(
        (s) => s['id'] == scheduleId,
        orElse: () => <String, dynamic>{},
      );
      if (schedule.isNotEmpty) {
        medName = schedule['med_name'] as String? ?? 'Obat TBC';
        final timeStr = schedule['schedule_time'] as String?;
        if (timeStr != null && timeStr.length >= 5) {
          scheduleTime = timeStr.substring(0, 5);
        }
      }
    }

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      try {
        context.push(
          '/confirm-medication',
          extra: {
            'scheduleId': scheduleId,
            'medName': medName,
            'scheduleTime': scheduleTime,
            'homeViewModel': this,
          },
        );
      } catch (e) {
        debugPrint('Navigation to confirm-medication failed: $e');
      }
    }
  }
}
