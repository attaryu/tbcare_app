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
      var tpList = await _supabase.client
          .from('treatment_periods')
          .select()
          .eq('patients_id', userId)
          .eq('status', 'active');

      // Seeder: If no active treatment period exists, create one with schedules
      if (tpList.isEmpty) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final pred = DateTime(now.year, now.month + 6, 29);

        final insertedTpList = await _supabase.client.from('treatment_periods').insert({
          'patients_id': userId,
          'name': 'Fase Intensif',
          'start_date': start.toIso8601String().split('T')[0],
          'prediction_end_date': pred.toIso8601String().split('T')[0],
          'duration': 6,
          'duration_type': 'month',
          'status': 'active',
        }).select();

        if (insertedTpList.isNotEmpty) {
          tpList = insertedTpList;
        }
      }

      if (tpList.isNotEmpty) {
        final tpRes = tpList.first;
        activeTreatment = Map<String, dynamic>.from(tpRes);
        final tpId = tpRes['id'] as int;

        // Calculate days passed
        final startDate = DateTime.parse(tpRes['start_date']);
        daysPassed = DateTime.now().difference(startDate).inDays;
        if (daysPassed < 0) daysPassed = 0;

        // Fetch medication schedules
        var schedRes = await _supabase.client
            .from('medication_schedules')
            .select()
            .eq('treatment_period_id', tpId)
            .order('schedule_time');

        var schedList = List<Map<String, dynamic>>.from(schedRes);

        // Seeder: If treatment period has no schedules, seed 5 medication schedules
        if (schedList.isEmpty) {
          final schedsToInsert = [
            {'treatment_period_id': tpId, 'med_name': 'Obat TBC - Isoniazid', 'schedule_time': '08:45:00'},
            {'treatment_period_id': tpId, 'med_name': 'Obat TBC - Rifampicin', 'schedule_time': '12:10:00'},
            {'treatment_period_id': tpId, 'med_name': 'Obat Flu', 'schedule_time': '12:10:00'},
            {'treatment_period_id': tpId, 'med_name': 'Obat Nyeri Otot', 'schedule_time': '19:25:00'},
            {'treatment_period_id': tpId, 'med_name': 'Obat TBC - Isoniazid', 'schedule_time': '19:25:00'},
          ];

          final insertedScheds = await _supabase.client.from('medication_schedules').insert(schedsToInsert).select();
          schedList = List<Map<String, dynamic>>.from(insertedScheds);
        }

        if (schedList.isNotEmpty) {
          final schedIds = schedList.map((s) => s['id'] as int).toList();

          final todayStr = DateTime.now().toIso8601String().split('T')[0];
          final startOfDay = '${todayStr}T00:00:00';
          final endOfDay = '${todayStr}T23:59:59';

          // Fetch compliance logs for today using taken_at range
          final compRes = await _supabase.client
              .from('compliance_logs')
              .select()
              .gte('taken_at', startOfDay)
              .lte('taken_at', endOfDay)
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
      'daysPassed': daysPassed > 0 ? daysPassed : 50,
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

  Future<void> logMedicationTaken(int scheduleId, {String? photoUrl}) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final startOfDay = '${todayStr}T00:00:00';
    final endOfDay = '${todayStr}T23:59:59';

    // Get medicine name first
    final schedRes = await _supabase.client
        .from('medication_schedules')
        .select('med_name')
        .eq('id', scheduleId);
    String medName = 'Obat TBC';
    if (schedRes.isNotEmpty) {
      medName = schedRes.first['med_name'] ?? 'Obat TBC';
    }

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
          .update({
            'status': 'taken',
            'taken_at': now.toIso8601String(),
            'photo_url': photoUrl,
          })
          .eq('id', existing['id']);
    } else {
      await _supabase.client.from('compliance_logs').insert({
        'schedule_id': scheduleId,
        'med_name': medName,
        'status': 'taken',
        'taken_at': now.toIso8601String(),
        'photo_url': photoUrl,
      });
    }
  }
}
