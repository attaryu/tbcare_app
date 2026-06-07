import '../models/medication_schedule_model.dart';
import '../services/supabase_service.dart';

class MedicationScheduleRepository {
  final SupabaseService _supabase;

  MedicationScheduleRepository(this._supabase);

  Future<Map<String, dynamic>?> getActiveTreatmentPeriod(int userId) async {
    final res = await _supabase.client
        .from('treatment_periods')
        .select()
        .eq('patients_id', userId)
        .eq('status', 'active');

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<List<MedicationScheduleModel>> getMedicationSchedules(int treatmentPeriodId) async {
    final res = await _supabase.client
        .from('medication_schedules')
        .select()
        .eq('treatment_period_id', treatmentPeriodId)
        .order('schedule_time');

    return (res as List).map((json) => MedicationScheduleModel.fromJson(json)).toList();
  }

  Future<void> addMedicationSchedule(MedicationScheduleModel schedule) async {
    await _supabase.client.from('medication_schedules').insert(schedule.toJson());
  }

  Future<void> updateMedicationSchedule(int id, String medName, String scheduleTime) async {
    await _supabase.client
        .from('medication_schedules')
        .update({
          'med_name': medName,
          'schedule_time': scheduleTime,
        })
        .eq('id', id);
  }

  Future<void> deleteMedicationSchedule(int id) async {
    await _supabase.client.from('medication_schedules').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getSchedulesForAlarmSync(int userId) async {
    final period = await getActiveTreatmentPeriod(userId);
    if (period == null) return [];

    final tpId = period['id'] as int;
    final schedRes = await _supabase.client
        .from('medication_schedules')
        .select()
        .eq('treatment_period_id', tpId);

    final schedList = List<Map<String, dynamic>>.from(schedRes);
    if (schedList.isEmpty) return [];

    final schedIds = schedList.map((s) => s['id'] as int).toList();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final compRes = await _supabase.client
        .from('compliance_logs')
        .select('schedule_id, status')
        .eq('log_date', todayStr)
        .inFilter('schedule_id', schedIds);

    final compMap = {
      for (var item in compRes)
        item['schedule_id'] as int: item['status'] as String
    };

    for (var s in schedList) {
      final sId = s['id'] as int;
      String status = 'Segera';
      if (compMap.containsKey(sId)) {
        final st = compMap[sId];
        if (st == 'taken') status = 'Tepat waktu';
        if (st == 'missed') status = 'Terlewat';
        if (st == 'pending') status = 'Segera';
      } else {
        try {
          final timeStr = s['schedule_time'] as String;
          final now = DateTime.now();
          final parts = timeStr.split(':');
          final sTime = DateTime(now.year, now.month, now.day,
              int.parse(parts[0]), int.parse(parts[1]));
          if (now.isAfter(sTime)) {
            status = 'Terlewat';
          }
        } catch (_) {}
      }
      s['today_status'] = status;
    }

    return schedList;
  }
}
