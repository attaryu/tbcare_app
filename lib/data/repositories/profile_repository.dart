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

    final existing = await _supabase.client
        .from('supervisions_patients')
        .select()
        .eq('patients_id', patientId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.client
          .from('supervisions_patients')
          .update({
            'supervision_id': supervisionId,
            'status': 'pending',
            'request_at': DateTime.now().toIso8601String(),
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
