import '../services/supabase_service.dart';

class HistoryRepository {
  final SupabaseService _supabase;

  HistoryRepository(this._supabase);

  Future<Map<String, dynamic>> getHistoryData(int userId, DateTime currentMonth) async {
    // 1. Fetch active treatment period
    final tpList = await _supabase.client
        .from('treatment_periods')
        .select()
        .eq('patients_id', userId)
        .eq('status', 'active');

    Map<String, dynamic>? activeTreatment;
    List<Map<String, dynamic>> schedules = [];
    List<Map<String, dynamic>> logs = [];

    if (tpList.isNotEmpty) {
      final tpRes = tpList.first;
      activeTreatment = Map<String, dynamic>.from(tpRes);
      final tpId = tpRes['id'] as int;

      // 2. Fetch medication schedules
      final schedRes = await _supabase.client
          .from('medication_schedules')
          .select()
          .eq('treatment_period_id', tpId)
          .order('schedule_time');

      schedules = List<Map<String, dynamic>>.from(schedRes);

      if (schedules.isNotEmpty) {
        final schedIds = schedules.map((s) => s['id'] as int).toList();

        // 3. Fetch all compliance logs for these schedules in currentMonth
        final firstDayStr = "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-01";
        final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
        final lastDayStr = "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}";

        final compRes = await _supabase.client
            .from('compliance_logs')
            .select()
            .inFilter('schedule_id', schedIds)
            .gte('log_date', firstDayStr)
            .lte('log_date', lastDayStr);

        logs = List<Map<String, dynamic>>.from(compRes);
      }
    }

    // Process statistics accurately based on actual database logs
    int terverifikasi = 0;
    int tidakTerverifikasi = 0;
    int terlambat = 0;
    int terlewat = 0;

    for (var log in logs) {
      final st = log['status'];
      final verifiedBy = log['verified_by'];

      if (st == 'taken') {
        if (verifiedBy != null) {
          terverifikasi++;
        } else {
          tidakTerverifikasi++;
        }
      } else if (st == 'missed') {
        terlewat++;
      }
    }

    final total = terverifikasi + tidakTerverifikasi + terlambat + terlewat;
    final double percentage = total > 0 ? ((terverifikasi + tidakTerverifikasi) / total * 100.0) : 0.0;

    return {
      'activeTreatment': activeTreatment,
      'schedules': schedules,
      'logs': logs,
      'stats': {
        'terverifikasi': terverifikasi,
        'tidakTerverifikasi': tidakTerverifikasi,
        'terlambat': terlambat,
        'terlewat': terlewat,
        'percentage': percentage,
      }
    };
  }

  Future<void> updateLogStatus(int scheduleId, String medName, String dateStr, String newStatus) async {
    final startOfDay = '${dateStr}T00:00:00';
    final endOfDay = '${dateStr}T23:59:59';

    final existingList = await _supabase.client
        .from('compliance_logs')
        .select()
        .eq('schedule_id', scheduleId)
        .gte('taken_at', startOfDay)
        .lte('taken_at', endOfDay);

    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      await _supabase.client
          .from('compliance_logs')
          .update({'status': newStatus, 'taken_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      await _supabase.client.from('compliance_logs').insert({
        'schedule_id': scheduleId,
        'med_name': medName,
        'status': newStatus,
        'taken_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
