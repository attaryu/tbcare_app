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
        .select('*, users:patients_id(id, name, photo_url)')
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
}
