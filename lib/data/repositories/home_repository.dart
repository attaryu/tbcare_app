import 'package:flutter/foundation.dart';
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

        // Fetch medication schedules
        final schedRes = await _supabase.client
            .from('medication_schedules')
            .select()
            .eq('treatment_period_id', tpId)
            .order('schedule_time');

        final schedList = List<Map<String, dynamic>>.from(schedRes);

        if (schedList.isNotEmpty) {
          // 3.1 Initialize daily compliance logs dynamically in background
          await _initializeDailyComplianceLogs(userId, tpRes, schedList);

          final schedIds = schedList.map((s) => s['id'] as int).toList();

          final todayStr = DateTime.now().toIso8601String().split('T')[0];

          // Fetch compliance logs for today using log_date
          final compRes = await _supabase.client
              .from('compliance_logs')
              .select('schedule_id, status, verified_by')
              .eq('log_date', todayStr)
              .inFilter('schedule_id', schedIds);

          final compMap = {
            for (var item in compRes)
              item['schedule_id'] as int: {
                'status': item['status'],
                'verified_by': item['verified_by'],
              }
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

          // Build schedule items with today's status
          for (var s in schedList) {
            final sId = s['id'] as int;
            String status = 'Segera';
            bool isVerified = false;

            if (compMap.containsKey(sId)) {
              final logData = compMap[sId];
              final st = logData?['status'];
              isVerified = logData?['verified_by'] != null;

              if (st == 'taken') status = 'Di minum';
              if (st == 'missed') status = 'Terlewat';
              if (st == 'pending') status = 'Segera';
            } else {
              // Check time comparison safely (fallback if initialization not yet run/failed)
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
            s['is_verified'] = isVerified;
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
      'complianceRate': totalCount > 0 ? (takenCount / totalCount * 100.0) : 0.0,
      'daysPassed': daysPassed,
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
        .eq('log_date', todayStr);

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
        'log_date': todayStr,
      });
    }
  }

  Future<void> upsertMissedLog(int scheduleId, String medName) async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    final existing = await _supabase.client
        .from('compliance_logs')
        .select('status')
        .eq('schedule_id', scheduleId)
        .eq('log_date', todayStr)
        .maybeSingle();

    if (existing == null) {
      await _supabase.client.from('compliance_logs').insert({
        'schedule_id': scheduleId,
        'med_name': medName,
        'status': 'missed',
        'log_date': todayStr,
      });
    } else if (existing['status'] == 'pending') {
      await _supabase.client
          .from('compliance_logs')
          .update({'status': 'missed'})
          .eq('schedule_id', scheduleId)
          .eq('log_date', todayStr);
    }
  }

  Future<void> _initializeDailyComplianceLogs(
    int userId,
    Map<String, dynamic> activeTreatment,
    List<Map<String, dynamic>> schedules,
  ) async {
    try {
      if (schedules.isEmpty) return;
      final schedIds = schedules.map((s) => s['id'] as int).toList();

      // Update compliance logs kemarin yang masih pending menjadi missed secara berkala di database
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await _supabase.client
          .from('compliance_logs')
          .update({'status': 'missed'})
          .inFilter('schedule_id', schedIds)
          .eq('status', 'pending')
          .lt('log_date', todayStr);

      // 1. Dapatkan tanggal kepatuhan terakhir dari database
      final lastLogRes = await _supabase.client
          .from('compliance_logs')
          .select('log_date')
          .inFilter('schedule_id', schedIds)
          .order('log_date', ascending: false)
          .limit(1);

      DateTime startGenerationDate;
      if (lastLogRes.isNotEmpty) {
        // Mulai dari satu hari setelah tanggal log terakhir
        final lastLogDate = DateTime.parse(lastLogRes.first['log_date'] as String);
        startGenerationDate = DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day + 1);
      } else {
        // Fallback ke start_date dari treatment period
        final startDate = DateTime.parse(activeTreatment['start_date'] as String);
        startGenerationDate = DateTime(startDate.year, startDate.month, startDate.day);
      }

      // 2. Batasi tanggal selesai maksimum tidak melebihi prediction_end_date
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      final predictionEndDate = DateTime.parse(activeTreatment['prediction_end_date'] as String);
      final endGenerationDate = todayOnly.isBefore(predictionEndDate) ? todayOnly : predictionEndDate;

      // Jika tanggal mulai melampaui tanggal selesai, tidak perlu generate
      if (startGenerationDate.isAfter(endGenerationDate)) return;

      List<Map<String, dynamic>> newLogs = [];

      // 3. Iterasi setiap hari dalam rentang yang telah dihitung
      for (var day = startGenerationDate; !day.isAfter(endGenerationDate); day = day.add(const Duration(days: 1))) {
        final dateStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        final isToday = day.year == todayOnly.year && day.month == todayOnly.month && day.day == todayOnly.day;

        for (var s in schedules) {
          final sId = s['id'] as int;
          String status = 'missed';

          if (isToday) {
            // Periksa waktu hari ini secara real-time
            final timeStr = s['schedule_time'] as String;
            final parts = timeStr.split(':');
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final sTime = DateTime(now.year, now.month, now.day, hour, minute);

            status = now.isAfter(sTime) ? 'missed' : 'pending';
          }

          newLogs.add({
            'schedule_id': sId,
            'med_name': s['med_name'],
            'status': status,
            'log_date': dateStr,
            'taken_at': null,
          });
        }
      }

      // 4. Masukkan log ke database sekaligus menggunakan bulk insert
      if (newLogs.isNotEmpty) {
        await _supabase.client.from('compliance_logs').insert(newLogs);
      }
    } catch (e) {
      debugPrint('Error in _initializeDailyComplianceLogs: $e');
    }
  }
}
