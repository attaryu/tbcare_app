import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final SupabaseService _supabase;

  ProfileRepository(this._supabase);

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    // 1. Fetch user data
    final userRes = await _supabase.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    final user = UserModel.fromJson(userRes);

    // 2. Fetch role
    String roleSlug = 'pasien';
    String roleName = 'Pasien';

    final userRoleRes = await _supabase.client
        .from('user_roles')
        .select('role_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (userRoleRes != null) {
      final roleId = userRoleRes['role_id'] as int;
      final roleRes = await _supabase.client
          .from('roles')
          .select('slug, name')
          .eq('id', roleId)
          .single();
      roleSlug = roleRes['slug'] as String;
      roleName = roleRes['name'] as String;
    }

    Map<String, dynamic>? supervisorInfo;
    Map<String, dynamic>? treatmentPeriod;
    List<Map<String, dynamic>> medicationSchedules = [];
    String? supervisorCode;

    if (roleSlug == 'pasien') {
      // Fetch supervision
      final spRes = await _supabase.client
          .from('supervisions_patients')
          .select()
          .eq('patients_id', userId)
          .inFilter('status', ['pending', 'approved'])
          .maybeSingle();

      if (spRes != null) {
        final supervisionId = spRes['supervision_id'] as int;
        final status = spRes['status'] as String;

        final supRes = await _supabase.client
            .from('supervisions')
            .select()
            .eq('id', supervisionId)
            .single();
        final code = supRes['supervision_code'] as String;
        final supervisorId = supRes['supervisor_id'] as int;

        final supervisorUserRes = await _supabase.client
            .from('users')
            .select('name, telephone_number')
            .eq('id', supervisorId)
            .single();

        supervisorInfo = {
          'name': supervisorUserRes['name'],
          'telephone': supervisorUserRes['telephone_number'] ?? '-',
          'code': code,
          'status': status,
        };
      }

      // Fetch active treatment period
      final tpRes = await _supabase.client
          .from('treatment_periods')
          .select()
          .eq('patients_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (tpRes != null) {
        treatmentPeriod = Map<String, dynamic>.from(tpRes);
        final tpId = tpRes['id'] as int;

        final schedRes = await _supabase.client
            .from('medication_schedules')
            .select()
            .eq('treatment_period_id', tpId);
        medicationSchedules = List<Map<String, dynamic>>.from(schedRes);
      }
    } else if (roleSlug == 'pengawas') {
      final supRes = await _supabase.client
          .from('supervisions')
          .select('supervision_code')
          .eq('supervisor_id', userId)
          .maybeSingle();
      if (supRes != null) {
        supervisorCode = supRes['supervision_code'] as String?;
      }
    }

    return {
      'user': user,
      'roleSlug': roleSlug,
      'roleName': roleName,
      'supervisorInfo': supervisorInfo,
      'treatmentPeriod': treatmentPeriod,
      'medicationSchedules': medicationSchedules,
      'supervisorCode': supervisorCode,
    };
  }

  Future<void> addSupervisor(int patientId, String code) async {
    final sup = await _supabase.client
        .from('supervisions')
        .select()
        .eq('supervision_code', code)
        .maybeSingle();

    if (sup == null) {
      throw 'Kode Pengawas tidak valid atau tidak ditemukan.';
    }

    final supervisionId = sup['id'] as int;

    // Check if there is an existing relationship with this specific supervisor (any status)
    final existingRelation = await _supabase.client
        .from('supervisions_patients')
        .select()
        .eq('patients_id', patientId)
        .eq('supervision_id', supervisionId)
        .maybeSingle();

    if (existingRelation != null) {
      // Re-apply to the same supervisor by updating status to pending
      await _supabase.client
          .from('supervisions_patients')
          .update({
            'status': 'pending',
            'request_at': DateTime.now().toIso8601String(),
            'joined_at': null,
          })
          .eq('id', existingRelation['id']);
    } else {
      // If no relationship exists with this supervisor, check if there is an active/pending relationship with a different supervisor
      final activeOrPendingRelation = await _supabase.client
          .from('supervisions_patients')
          .select()
          .eq('patients_id', patientId)
          .inFilter('status', ['pending', 'approved'])
          .maybeSingle();

      if (activeOrPendingRelation != null) {
        // If there's an active/pending relationship with another supervisor, update it to the new supervisor
        await _supabase.client
            .from('supervisions_patients')
            .update({
              'supervision_id': supervisionId,
              'status': 'pending',
              'request_at': DateTime.now().toIso8601String(),
              'joined_at': null,
            })
            .eq('id', activeOrPendingRelation['id']);
      } else {
        // Otherwise, insert a new relationship
        await _supabase.client
            .from('supervisions_patients')
            .insert({
              'supervision_id': supervisionId,
              'patients_id': patientId,
              'status': 'pending',
            });
      }
    }
  }

  Future<void> updateUserProfile(int userId, String name, String? phone) async {
    await _supabase.client
        .from('users')
        .update({
          'name': name,
          'telephone_number': phone,
        })
        .eq('id', userId);
  }
}
