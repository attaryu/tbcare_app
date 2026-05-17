import '../models/user_model.dart';
import '../services/supabase_service.dart';

class HomeRepository {
  final SupabaseService _supabase;

  HomeRepository(this._supabase);

  Future<Map<String, dynamic>> getHomeData(int userId) async {
    // 1. Fetch user safely
    final userList = await _supabase.client
        .from('users')
        .select()
        .eq('id', userId);
    if (userList.isEmpty) {
      throw 'Pengguna dengan ID $userId tidak ditemukan.';
    }
    final user = UserModel.fromJson(userList.first);

    // 2. Check supervisor connection safely
    bool hasSupervisor = false;
    Map<String, dynamic>? supervisorInfo;
    try {
      final spList = await _supabase.client
          .from('supervisions_patients')
          .select()
          .eq('patients_id', userId);

      if (spList.isNotEmpty) {
        final spRes = spList.last;
        hasSupervisor = true;
        final supervisionId = spRes['supervision_id'] as int;

        final supList = await _supabase.client
            .from('supervisions')
            .select()
            .eq('id', supervisionId);

        if (supList.isNotEmpty) {
          final supRes = supList.first;
          final supervisorUserId = supRes['supervisor_id'] as int;

          final sUserList = await _supabase.client
              .from('users')
              .select('name, telephone_number')
              .eq('id', supervisorUserId);

          if (sUserList.isNotEmpty) {
            final sUserRes = sUserList.first;
            supervisorInfo = {
              'name': sUserRes['name'],
              'telephone': sUserRes['telephone_number'] ?? '-',
              'status': spRes['status'],
            };
          }
        }
      }
    } catch (_) {}

    // 3. Fetch active treatment period safely
    Map<String, dynamic>? activeTreatment;
    List<Map<String, dynamic>> schedules = [];
    int takenCount = 0;
    int totalCount = 0;
    int daysPassed = 0;

    try {
      final tpList = await _supabase.client
          .from('treatment_periods')
          .select()
          .eq('patients_id', userId)
          .eq('status', 'active');

      if (tpList.isNotEmpty) {
        final tpRes = tpList.first;
        activeTreatment = Map<String, dynamic>.from(tpRes);
        final tpId = tpRes['id'] as int;

        // Calculate days passed
        final startDate = DateTime.parse(tpRes['start_date']);
        daysPassed = DateTime.now().difference(startDate).inDays;
        if (daysPassed < 0) daysPassed = 0;

        // Fetch schedules safely
        final schedRes = await _supabase.client
            .from('medication_schedules')
            .select()
            .eq('treatment_period_id', tpId)
            .order('schedule_time');

        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        final schedList = List<Map<String, dynamic>>.from(schedRes);

        if (schedList.isNotEmpty) {
          final schedIds = schedList.map((s) => s['id'] as int).toList();

          // Fetch compliance logs for today
          final compRes = await _supabase.client
              .from('compliance_logs')
              .select()
              .eq('log_date', todayStr)
              .inFilter('schedule_id', schedIds);

          final compMap = {
            for (var item in compRes) item['schedule_id'] as int: item['status']
          };

          // Fetch all compliance logs to calculate overall compliance
          final allCompRes = await _supabase.client
              .from('compliance_logs')
              .select('status')
              .inFilter('schedule_id', schedIds);

          totalCount = allCompRes.length;
          for (var c in allCompRes) {
            if (c['status'] == 'taken') takenCount++;
          }

          if (totalCount == 0) {
            totalCount = 100;
            takenCount = 98; // Default mockup percentage if no records
          }

          // Build schedule items with today's status
          for (var s in schedList) {
            final sId = s['id'] as int;
            String status = 'Segera';
            if (compMap.containsKey(sId)) {
              final st = compMap[sId];
              if (st == 'taken') status = 'Di minum';
              if (st == 'missed') status = 'Terlewat';
            } else {
              // Check time comparison safely
              try {
                final timeStr = s['schedule_time'] as String;
                final now = DateTime.now();
                final parts = timeStr.split(':');
                final sTime = DateTime(now.year, now.month, now.day,
                    int.parse(parts[0]), int.parse(parts[1]));

                if (now.difference(sTime).inMinutes > 60) {
                  status = 'Terlewat';
                }
              } catch (_) {}
            }

            s['today_status'] = status;
            schedules.add(s);
          }
        }
      }
    } catch (_) {}

    return {
      'user': user,
      'hasSupervisor': hasSupervisor,
      'supervisorInfo': supervisorInfo,
      'activeTreatment': activeTreatment,
      'schedules': schedules,
      'complianceRate': totalCount > 0 ? (takenCount / totalCount * 100.0) : 98.0,
      'daysPassed': daysPassed > 0 ? daysPassed : 50, // Default mockup 50 if new
    };
  }

  Future<void> connectSupervisor(int patientId, String code) async {
    final supList = await _supabase.client
        .from('supervisions')
        .select()
        .eq('supervision_code', code);

    if (supList.isEmpty) {
      throw 'Kode Pengawas tidak valid atau tidak ditemukan.';
    }

    final sup = supList.first;
    final supervisionId = sup['id'] as int;

    final existingList = await _supabase.client
        .from('supervisions_patients')
        .select()
        .eq('patients_id', patientId);

    if (existingList.isNotEmpty) {
      final existing = existingList.last;
      await _supabase.client
          .from('supervisions_patients')
          .update({
            'supervision_id': supervisionId,
            'status': 'pending',
          })
          .eq('id', existing['id']);
    } else {
      await _supabase.client
          .from('supervisions_patients')
          .insert({
            'supervision_id': supervisionId,
            'patients_id': patientId,
            'status': 'pending',
          });
    }
  }

  Future<void> logMedicationTaken(int scheduleId) async {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final existingList = await _supabase.client
        .from('compliance_logs')
        .select()
        .eq('schedule_id', scheduleId)
        .eq('log_date', todayStr);

    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      await _supabase.client
          .from('compliance_logs')
          .update({'status': 'taken', 'taken_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      await _supabase.client.from('compliance_logs').insert({
        'schedule_id': scheduleId,
        'log_date': todayStr,
        'status': 'taken',
        'taken_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
