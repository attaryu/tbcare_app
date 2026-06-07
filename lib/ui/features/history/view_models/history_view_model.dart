import 'package:flutter/material.dart';
import '../../../../data/models/symptom_model.dart';
import '../../../../data/repositories/history_repository.dart';
import '../../../../data/repositories/symptom_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repository;
  final SymptomRepository? _symptomRepository;
  final int _userId;

  HistoryViewModel({
    required HistoryRepository repository,
    required int userId,
    SymptomRepository? symptomRepository,
  })  : _repository = repository,
        _symptomRepository = symptomRepository,
        _userId = userId {
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    fetchHistoryData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  late DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  late DateTime _currentMonth;
  DateTime get currentMonth => _currentMonth;

  Map<String, dynamic>? _activeTreatment;
  Map<String, dynamic>? get activeTreatment => _activeTreatment;

  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> get schedules => _schedules;

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> get logs => _logs;

  Map<String, dynamic> _stats = {
    'terverifikasi': 0,
    'tidakTerverifikasi': 0,
    'terlambat': 0,
    'terlewat': 0,
    'percentage': 0.0,
  };
  Map<String, dynamic> get stats => _stats;

  DateTime? getTreatmentStartDate() {
    if (_activeTreatment == null) return null;
    try {
      final st = DateTime.parse(_activeTreatment!['start_date']);
      return DateTime(st.year, st.month, st.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? getTreatmentEndDate() {
    if (_activeTreatment == null) return null;
    try {
      final ed = DateTime.parse(_activeTreatment!['prediction_end_date']);
      return DateTime(ed.year, ed.month, ed.day);
    } catch (_) {
      return null;
    }
  }

  int get totalTreatmentDaysInCurrentMonth {
    final start = getTreatmentStartDate();
    final end = getTreatmentEndDate();
    if (start == null || end == null) return 0;

    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final activeStart = start.isAfter(monthStart) ? start : monthStart;
    final activeEnd = end.isBefore(monthEnd) ? end : monthEnd;

    if (activeStart.isAfter(activeEnd)) return 0;
    return activeEnd.difference(activeStart).inDays + 1;
  }

  int get passedTreatmentDaysInCurrentMonth {
    final start = getTreatmentStartDate();
    final end = getTreatmentEndDate();
    if (start == null || end == null) return 0;

    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final activeStart = start.isAfter(monthStart) ? start : monthStart;
    final activeEnd = end.isBefore(monthEnd) ? end : monthEnd;

    if (activeStart.isAfter(activeEnd)) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveEnd = today.isBefore(activeEnd) ? today : activeEnd;

    if (activeStart.isAfter(effectiveEnd)) return 0;
    return effectiveEnd.difference(activeStart).inDays + 1;
  }

  /// Getter to calculate active schedule IDs (closest upcoming schedules)
  /// only if the selected date is today.
  Set<int> get activeScheduleIds {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    if (!isToday || _schedules.isEmpty) return {};

    final todayPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final dailySchedules = getSchedulesForSelectedDate();
    // Only pending schedules (upcoming, not yet taken or missed)
    final pending = dailySchedules.where((s) => s['status'] == 'Segera').toList();
    if (pending.isEmpty) return {};

    Duration? minDiff;
    for (final s in pending) {
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null) continue;
      final timePart = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      final schedDateTime = DateTime.tryParse('${todayPrefix}T$timePart:00');
      if (schedDateTime == null) continue;

      final diff = schedDateTime.difference(now).abs();
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
      }
    }

    if (minDiff == null) return {};

    final closestIds = <int>{};
    for (final s in pending) {
      final timeStr = s['schedule_time'] as String?;
      if (timeStr == null) continue;
      final timePart = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      final schedDateTime = DateTime.tryParse('${todayPrefix}T$timePart:00');
      if (schedDateTime == null) continue;

      final diff = schedDateTime.difference(now).abs();
      if ((diff - minDiff).inSeconds.abs() == 0) {
        closestIds.add(s['id'] as int);
      }
    }

    return closestIds;
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
      _currentMonth = DateTime(date.year, date.month);
      fetchHistoryData();
    } else {
      _loadSymptomsForSelectedDate();
    }
  }

  Future<void> _loadSymptomsForSelectedDate() async {
    await fetchSymptomsForSelectedDate();
    notifyListeners();
  }

  bool get canNavigateToPreviousMonth {
    final startDate = getTreatmentStartDate();
    if (startDate == null) return true;
    final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0);
    return !prevMonthLastDay.isBefore(startDate);
  }

  bool get canNavigateToNextMonth {
    final endDate = getTreatmentEndDate();
    if (endDate == null) return true;
    final nextMonthFirstDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return !nextMonthFirstDay.isAfter(endDate);
  }

  void previousMonth() {
    if (!canNavigateToPreviousMonth) return;
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    fetchHistoryData();
  }

  void nextMonth() {
    if (!canNavigateToNextMonth) return;
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _repository.getHistoryData(_userId, _currentMonth);
      _activeTreatment = res['activeTreatment'];
      _schedules = res['schedules'];
      _logs = res['logs'];
      _stats = res['stats'];
      
      await fetchSymptomsForSelectedDate();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SymptomLog> _symptomsForSelectedDate = [];
  List<SymptomLog> get symptomsForSelectedDate => _symptomsForSelectedDate;

  Future<void> fetchSymptomsForSelectedDate() async {
    if (_symptomRepository == null || _activeTreatment == null) {
      _symptomsForSelectedDate = [];
      return;
    }
    final tpId = _activeTreatment!['id'] as int?;
    if (tpId == null) {
      _symptomsForSelectedDate = [];
      return;
    }
    try {
      _symptomsForSelectedDate = await _symptomRepository.getSymptomLogsByDate(tpId, _selectedDate);
    } catch (e) {
      debugPrint('Error fetching symptoms: $e');
      _symptomsForSelectedDate = [];
    }
  }

  String getDayStatus(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);

    // Filter tanggal di luar periode pengobatan aktif
    final startDate = getTreatmentStartDate();
    if (startDate != null && dateOnly.isBefore(startDate)) {
      return 'Diluar Periode';
    }

    final endDate = getTreatmentEndDate();
    if (endDate != null && dateOnly.isAfter(endDate)) {
      return 'Diluar Periode';
    }

    if (dateOnly.isAfter(todayOnly)) {
      return 'Mendatang';
    }

    final dateStr = date.toIso8601String().split('T')[0];
    final dateLogs = _logs.where((l) => l['log_date'] == dateStr).toList();

    final totalSchedules = _schedules.length;
    if (totalSchedules == 0) {
      return 'Mendatang';
    }

    int taken = 0;
    int missed = 0;
    for (var l in dateLogs) {
      if (l['status'] == 'taken') taken++;
      if (l['status'] == 'missed') missed++;
    }

    if (dateOnly.isBefore(todayOnly)) {
      // Hari di masa lalu:
      if (taken == totalSchedules) {
        return 'Penuh';
      } else if (taken > 0) {
        return 'Sebagian';
      } else {
        return 'Terlewat';
      }
    } else {
      // Hari ini (dateOnly == todayOnly):
      if (taken == totalSchedules) {
        return 'Penuh';
      } else if (taken > 0) {
        return 'Sebagian';
      } else {
        // Jika belum diminum semua (taken == 0)
        // Cek apakah ada jadwal yang eksplisit dilewatkan (missed > 0)
        // atau jika ada jadwal yang sudah lewat waktunya hari ini
        int passedSchedulesCount = 0;
        for (var s in _schedules) {
          try {
            final timeStr = s['schedule_time'] as String;
            final parts = timeStr.split(':');
            final sTime = DateTime(now.year, now.month, now.day,
                int.parse(parts[0]), int.parse(parts[1]));
            if (now.isAfter(sTime)) {
              passedSchedulesCount++;
            }
          } catch (_) {}
        }
        
        if (missed > 0 || passedSchedulesCount > 0) {
          return 'Terlewat';
        }
        return 'Mendatang';
      }
    }
  }

  List<Map<String, dynamic>> getSchedulesForSelectedDate() {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final dateLogs = {
      for (var l in _logs.where((l) => l['log_date'] == dateStr))
        l['schedule_id'] as int: l
    };

    List<Map<String, dynamic>> items = [];
    final isTodayOrPast = !_selectedDate.isAfter(DateTime.now());

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final isPastDate = _selectedDate.isBefore(todayOnly);

    if (_schedules.isNotEmpty) {
      for (var s in _schedules) {
        final sId = s['id'] as int;
        String st = 'Segera';
        bool isVerified = false;
        String? takenTime;
        if (dateLogs.containsKey(sId)) {
          final log = dateLogs[sId];
          final lSt = log?['status'] as String?;
          if (lSt == 'taken') {
            st = 'Tepat waktu';
            takenTime = log?['taken_at'] as String?;
          } else if (lSt == 'missed') {
            st = 'Terlewat';
          } else if (lSt == 'pending') {
            st = isPastDate ? 'Terlewat' : 'Segera';
          }
          isVerified = log?['verified_by'] != null;
        } else {
          if (isTodayOrPast && isPastDate) {
            st = 'Terlewat';
          }
        }
        items.add({
          'id': sId,
          'med_name': s['med_name'],
          'schedule_time': s['schedule_time'],
          'status': st,
          'is_verified': isVerified,
          'taken_time': takenTime,
        });
      }
      
      // Sort items chronologically (ascending) by schedule_time
      items.sort((a, b) {
        final timeA = a['schedule_time'] as String? ?? '';
        final timeB = b['schedule_time'] as String? ?? '';
        return timeA.compareTo(timeB);
      });
    }

    return items;
  }

  Future<void> toggleLogStatus(int scheduleId, String currentStatus) async {
    String newStatus = 'taken';
    if (currentStatus == 'Tepat waktu') newStatus = 'missed';
    if (currentStatus == 'Terlewat') newStatus = 'pending';

    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final sched = _schedules.firstWhere((s) => s['id'] == scheduleId, orElse: () => {'med_name': 'Obat TBC'});
    final medName = sched['med_name'] as String;

    try {
      await _repository.updateLogStatus(scheduleId, medName, dateStr, newStatus);
      await fetchHistoryData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
