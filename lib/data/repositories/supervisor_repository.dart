import '../services/supabase_service.dart';

class SupervisorRepository {
  final SupabaseService _supabase;

  SupervisorRepository(this._supabase);

  Future<String?> getSupervisorCode(int supervisorId) async {
    final res = await _supabase.client
        .from('supervisions')
        .select('supervision_code')
        .eq('supervisor_id', supervisorId)
        .maybeSingle();
    return res?['supervision_code'] as String?;
  }

  Future<int?> getSupervisionId(int supervisorId) async {
    final res = await _supabase.client
        .from('supervisions')
        .select('id')
        .eq('supervisor_id', supervisorId)
        .maybeSingle();
    return res?['id'] as int?;
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(int supervisorId) async {
    final supervisionId = await getSupervisionId(supervisorId);
    if (supervisionId == null) return [];

    final res = await _supabase.client
        .from('supervisions_patients')
        .select('*, users:patients_id(id, name, photo_url)')
        .eq('supervision_id', supervisionId)
        .eq('status', 'pending')
        .order('request_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getApprovedPatients(int supervisorId) async {
    final supervisionId = await getSupervisionId(supervisorId);
    if (supervisionId == null) return [];

    // Fetch approved patients and their user profiles
    final res = await _supabase.client
        .from('supervisions_patients')
        .select('*, users:patients_id(id, name, email, telephone_number, photo_url)')
        .eq('supervision_id', supervisionId)
        .eq('status', 'approved')
        .order('joined_at', ascending: false);

    final patients = List<Map<String, dynamic>>.from(res);

    // Fetch active treatment periods for each patient to display progress/phase details
    for (var patient in patients) {
      final patientId = patient['patients_id'];
      if (patientId != null) {
        final periodRes = await _supabase.client
            .from('treatment_periods')
            .select()
            .eq('patients_id', patientId)
            .eq('status', 'active')
            .maybeSingle();
        patient['active_period'] = periodRes;
      }
    }

    return patients;
  }

  Future<void> removePatient(int relationshipId) async {
    await _supabase.client
        .from('supervisions_patients')
        .update({
          'status': 'revoked',
        })
        .eq('id', relationshipId);
  }

  Future<void> acceptJoinRequest(int relationshipId) async {
    await _supabase.client
        .from('supervisions_patients')
        .update({
          'status': 'approved',
          'joined_at': DateTime.now().toIso8601String(),
        })
        .eq('id', relationshipId);
  }

  Future<void> rejectJoinRequest(int relationshipId) async {
    await _supabase.client
        .from('supervisions_patients')
        .update({
          'status': 'rejected',
        })
        .eq('id', relationshipId);
  }

  Future<List<Map<String, dynamic>>> getDailyPatientSummary(int supervisorId) async {
    final patients = await getApprovedPatients(supervisorId);

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final result = <Map<String, dynamic>>[];

    for (var patient in patients) {
      final activePeriod = patient['active_period'];
      if (activePeriod == null) continue;

      final periodId = activePeriod['id'] as int;
      final patientUser = patient['users'] as Map<String, dynamic>;

      final schedules = await _supabase.client
          .from('medication_schedules')
          .select()
          .eq('treatment_period_id', periodId)
          .order('schedule_time');

      if (schedules.isEmpty) continue;

      final schedList = List<Map<String, dynamic>>.from(schedules);
      final schedIds = schedList.map((s) => s['id'] as int).toList();

      final logs = await _supabase.client
          .from('compliance_logs')
          .select()
          .inFilter('schedule_id', schedIds)
          .eq('log_date', todayStr);

      final logList = List<Map<String, dynamic>>.from(logs);
      final logBySchedId = <int, Map<String, dynamic>>{};
      final missedLogIds = <int>[];

      for (var log in logList) {
        logBySchedId[log['schedule_id'] as int] = log;
        if ((log['status'] as String) == 'missed') {
          missedLogIds.add(log['id'] as int);
        }
      }

      final escalationByLogId = <int, int>{};
      if (missedLogIds.isNotEmpty) {
        final escalations = await _supabase.client
            .from('escalation_logs')
            .select()
            .inFilter('compliance_log_id', missedLogIds)
            .eq('status', 'triggered');

        for (var esc in List<Map<String, dynamic>>.from(escalations)) {
          escalationByLogId[esc['compliance_log_id'] as int] = esc['id'] as int;
        }
      }

      for (var sched in schedList) {
        final schedId = sched['id'] as int;
        final log = logBySchedId[schedId];
        if (log == null) continue;

        final logStatus = log['status'] as String;
        final verifiedBy = log['verified_by'];
        final logId = log['id'] as int;

        String category;
        if (logStatus == 'missed') {
          category = 'terlewat';
        } else if (logStatus == 'taken' && verifiedBy == null) {
          category = 'butuh_verifikasi';
        } else if (logStatus == 'taken' && verifiedBy != null) {
          category = 'aman';
        } else {
          continue;
        }

        result.add({
          'patient_id': patient['patients_id'],
          'relationship_id': patient['id'],
          'patient_name': patientUser['name'] ?? 'Pasien',
          'photo_url': patientUser['photo_url'],
          'telephone': patientUser['telephone_number'],
          'med_name': sched['med_name'],
          'schedule_time': sched['schedule_time'],
          'log_id': logId,
          'log_status': logStatus,
          'photo_evidence': log['photo_url'],
          'escalation_id': escalationByLogId[logId],
          'category': category,
        });
      }
    }

    return result;
  }

  Future<void> verifyComplianceLog(int logId, int supervisorId) async {
    await _supabase.client
        .from('compliance_logs')
        .update({
          'status': 'taken',
          'verified_by': supervisorId,
        })
        .eq('id', logId);
  }

  Future<void> rejectComplianceLog(int logId, String scheduleTime) async {
    final now = DateTime.now();
    final parts = scheduleTime.split(':');
    final schedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final newStatus = now.isAfter(schedDateTime) ? 'missed' : 'pending';

    await _supabase.client
        .from('compliance_logs')
        .update({
          'status': newStatus,
          'verified_by': null,
          'photo_url': null,
          'taken_at': null,
        })
        .eq('id', logId);

    if (newStatus == 'missed') {
      await _supabase.client
          .from('escalation_logs')
          .insert({
            'compliance_log_id': logId,
            'status': 'triggered',
          });
    }
  }

  Future<void> ignoreEscalation(int escalationId, int supervisorId) async {
    await _supabase.client
        .from('escalation_logs')
        .update({
          'status': 'ignored',
          'handled_by': supervisorId,
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', escalationId);
  }
}
