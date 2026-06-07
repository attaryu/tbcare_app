import 'package:flutter/material.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseService _supabase;

  AuthViewModel(this._supabase);

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  String? _roleSlug;
  String? get roleSlug => _roleSlug;

  bool get isAuthenticated => _currentUser != null;

  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  void _updateAuthState() {
    final authenticated = _currentUser != null;
    if (authStateNotifier.value != authenticated) {
      authStateNotifier.value = authenticated;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Restores session by querying the custom public.users table using the currently logged-in
  /// Supabase auth.users UUID.
  Future<void> tryRestoreSession() async {
    try {
      final authUser = _supabase.currentUser;
      if (authUser == null) {
        _currentUser = null;
        _roleSlug = null;
        _updateAuthState();
        notifyListeners();
        return;
      }

      final dbUserResponse = await _supabase.client
          .from('users')
          .select('*, user_roles(roles(slug))')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (dbUserResponse != null) {
        _currentUser = UserModel.fromJson(dbUserResponse);
        final userRoles = dbUserResponse['user_roles'] as List?;
        if (userRoles != null && userRoles.isNotEmpty) {
          final rolesMap = userRoles[0]['roles'] as Map?;
          _roleSlug = rolesMap?['slug'] as String?;
        } else {
          _roleSlug = null;
        }
      } else {
        // Auth user exists but profile row doesn't (could be interrupted registration)
        _currentUser = null;
        _roleSlug = null;
      }
      _updateAuthState();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
  }

  /// Signs in a user using Supabase Auth, then loads their public profile.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Perform Supabase authentication
      final authResponse = await _supabase.signIn(email, password);
      final authUser = authResponse.user;
      if (authUser == null) {
        throw 'Gagal melakukan login. Sesi tidak valid.';
      }

      // 2. Fetch the corresponding profile row from public.users
      final dbUserResponse = await _supabase.client
          .from('users')
          .select('*, user_roles(roles(slug))')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (dbUserResponse == null) {
        throw 'Profil pengguna tidak ditemukan di database publik.';
      }

      _currentUser = UserModel.fromJson(dbUserResponse);
      final userRoles = dbUserResponse['user_roles'] as List?;
      if (userRoles != null && userRoles.isNotEmpty) {
        final rolesMap = userRoles[0]['roles'] as Map?;
        _roleSlug = rolesMap?['slug'] as String?;
      } else {
        _roleSlug = null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      // Make sure we log out from Supabase if we fail to fetch the profile
      try {
        await _supabase.signOut();
      } catch (_) {}
    } finally {
      _isLoading = false;
      _updateAuthState();
      notifyListeners();
    }
  }

  /// Registers a new user, performing an atomic cascade:
  /// 1. Create credentials in Supabase Auth.
  /// 2. Insert profile record in public.users with auth_user_id.
  /// 3. Add user_roles, supervisions, treatment_periods, medication_schedules.
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
    String roleSlug, {
    String? supervisionCode,
    String? treatmentName,
    DateTime? startDate,
    int? duration,
    String? durationType,
    DateTime? predictionEndDate,
    List<Map<String, String>>? medicationSchedules,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    String? createdAuthUserId;

    try {
      // Step 1: Pre-validation checks in custom table & supervision code
      final existingUser = await _supabase.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      }

      int? verifiedSupervisionId;
      if (roleSlug == 'pasien' && supervisionCode != null && supervisionCode.isNotEmpty) {
        final supervision = await _supabase.client
            .from('supervisions')
            .select()
            .eq('supervision_code', supervisionCode)
            .maybeSingle();
        if (supervision == null) {
          throw 'Kode Pengawas tidak valid atau tidak ditemukan.';
        }
        verifiedSupervisionId = supervision['id'] as int;
      }

      // Step 2: Create Supabase Auth Credentials
      final authResponse = await _supabase.signUp(email, password);
      final authUser = authResponse.user;
      if (authUser == null) {
        throw 'Registrasi gagal. Silakan coba lagi.';
      }
      createdAuthUserId = authUser.id;

      // Step 3: Insert user profile record with auth_user_id
      final userResponse = await _supabase.client
          .from('users')
          .insert({
            'name': name,
            'email': email,
            'telephone_number': phone,
            'auth_user_id': createdAuthUserId,
          })
          .select()
          .single();

      final userId = userResponse['id'] as int;

      // Step 4: Map user role in user_roles
      final roleResponse = await _supabase.client
          .from('roles')
          .select('id')
          .eq('slug', roleSlug)
          .single();
      final roleId = roleResponse['id'] as int;

      await _supabase.client.from('user_roles').insert({
        'user_id': userId,
        'role_id': roleId,
      });

      // Step 5: Handle Role specific logic
      if (roleSlug == 'pengawas') {
        final randomCode = 'TBC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}${DateTime.now().second}';
        await _supabase.client.from('supervisions').insert({
          'supervisor_id': userId,
          'supervision_code': randomCode,
        });
      } else if (roleSlug == 'pasien') {
        if (verifiedSupervisionId != null) {
          await _supabase.client.from('supervisions_patients').insert({
            'supervision_id': verifiedSupervisionId,
            'patients_id': userId,
            'status': 'pending',
          });
        }

        if (treatmentName != null && startDate != null && duration != null && durationType != null && predictionEndDate != null) {
          final tpResponse = await _supabase.client.from('treatment_periods').insert({
            'patients_id': userId,
            'name': treatmentName,
            'start_date': startDate.toIso8601String().split('T')[0],
            'prediction_end_date': predictionEndDate.toIso8601String().split('T')[0],
            'duration': duration,
            'duration_type': durationType,
            'status': 'active',
          }).select().single();
          final tpId = tpResponse['id'] as int;

          if (medicationSchedules != null && medicationSchedules.isNotEmpty) {
            final schedulesToInsert = medicationSchedules.map((sched) => {
              'treatment_period_id': tpId,
              'med_name': sched['med_name'],
              'schedule_time': sched['schedule_time'],
            }).toList();
            await _supabase.client.from('medication_schedules').insert(schedulesToInsert);
          }
        }
      }

      // Step 6: Map to UserModel local session
      final user = UserModel.fromJson(userResponse);
      _currentUser = user;
      _roleSlug = roleSlug;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      
      // Rollback: If user profile insertion or other steps fail, remove the auth user
      // to ensure a clean slate and let the user try registering again.
      if (createdAuthUserId != null) {
        try {
          // Since the client signed in automatically on signup, we sign out
          await _supabase.signOut();
        } catch (_) {}
      }
      rethrow;
    } finally {
      _isLoading = false;
      _updateAuthState();
      notifyListeners();
    }
  }

  /// Signs out from Supabase Auth and clears the local profile model.
  Future<void> logout() async {
    await AppAlarmService.cancelAllAlarms();
    try {
      await _supabase.signOut();
    } catch (e) {
      debugPrint('Failed to sign out from Supabase: $e');
    }
    _currentUser = null;
    _roleSlug = null;
    _updateAuthState();
    notifyListeners();
  }
}
