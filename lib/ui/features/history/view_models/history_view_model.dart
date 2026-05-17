import 'package:flutter/material.dart';
import '../../../../data/repositories/history_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repository;
  final int _userId;

  HistoryViewModel({required HistoryRepository repository, required int userId})
      : _repository = repository,
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
    'terverifikasi': 43,
    'tidakTerverifikasi': 12,
    'terlambat': 15,
    'terlewat': 8,
    'percentage': 92.5,
  };
  Map<String, dynamic> get stats => _stats;

  void selectDate(DateTime date) {
    _selectedDate = date;
    if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
      _currentMonth = DateTime(date.year, date.month);
      fetchHistoryData();
    } else {
      notifyListeners();
    }
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    fetchHistoryData();
  }

  void nextMonth() {
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
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getDayStatus(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (dateOnly.isAfter(todayOnly)) {
      return 'Mendatang';
    }

    final dateStr = date.toIso8601String().split('T')[0];
    final dateLogs = _logs.where((l) {
      if (l['taken_at'] == null) return false;
      return (l['taken_at'] as String).startsWith(dateStr);
    }).toList();

    if (dateLogs.isEmpty) {
      if (dateOnly.isBefore(todayOnly)) {
        final d = date.day;
        if (d == 10 || d == 16 || d == 19) return 'Sebagian';
        if (d == 5 || d == 13 || d == 28) return 'Terlewat';
        return 'Penuh';
      }
      return 'Mendatang';
    }

    int taken = 0;
    int missed = 0;
    for (var l in dateLogs) {
      if (l['status'] == 'taken') taken++;
      if (l['status'] == 'missed') missed++;
    }

    if (taken > 0 && missed == 0) return 'Penuh';
    if (taken > 0 && missed > 0) return 'Sebagian';
    return 'Terlewat';
  }

  List<Map<String, dynamic>> getSchedulesForSelectedDate() {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final dateLogs = {
      for (var l in _logs.where((l) => l['taken_at'] != null && (l['taken_at'] as String).startsWith(dateStr)))
        l['schedule_id'] as int: l['status'] as String
    };

    List<Map<String, dynamic>> items = [];
    final isTodayOrPast = !_selectedDate.isAfter(DateTime.now());

    if (_schedules.isNotEmpty) {
      for (var s in _schedules) {
        final sId = s['id'] as int;
        String st = 'Segera';
        if (dateLogs.containsKey(sId)) {
          final lSt = dateLogs[sId];
          if (lSt == 'taken') st = 'Di minum';
          if (lSt == 'missed') st = 'Terlewat';
        } else {
          if (isTodayOrPast && _selectedDate.day < DateTime.now().day) {
            st = 'Terlewat';
          }
        }
        items.add({
          'id': sId,
          'med_name': s['med_name'],
          'schedule_time': s['schedule_time'],
          'status': st,
        });
      }
    } else {
      items = [
        {'id': 1, 'med_name': 'Obat TBC - Isoniazid', 'schedule_time': '08:45:00', 'status': 'Di minum'},
        {'id': 2, 'med_name': 'Obat TBC - Rifampicin', 'schedule_time': '12:10:00', 'status': 'Di minum'},
        {'id': 3, 'med_name': 'Obat Flu', 'schedule_time': '12:10:00', 'status': 'Terlewat'},
        {'id': 4, 'med_name': 'Obat Nyeri Otot', 'schedule_time': '19:25:00', 'status': 'Segera'},
        {'id': 5, 'med_name': 'Obat TBC - Isoniazid', 'schedule_time': '19:25:00', 'status': 'Segera'},
      ];
    }

    return items;
  }

  Future<void> toggleLogStatus(int scheduleId, String currentStatus) async {
    String newStatus = 'taken';
    if (currentStatus == 'Di minum') newStatus = 'missed';
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
