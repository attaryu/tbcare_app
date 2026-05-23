import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseService _supabase;
  static const String _sessionKey = 'user_session';

  AuthViewModel(this._supabase);

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSession = prefs.getString(_sessionKey);
      
      if (cachedSession == null) {
        return;
      }

      // Restore locally cached session temporarily
      final localUser = UserModel.fromJson(jsonDecode(cachedSession));
      _currentUser = localUser;
      notifyListeners();

      // DB First: Verify and fetch fresh user data from database
      try {
        final dbUserResponse = await _supabase.client
            .from('users')
            .select()
            .eq('id', localUser.id)
            .maybeSingle();

        if (dbUserResponse != null) {
          // Fresh user found, update local model & save fresh cache
          final freshUser = UserModel.fromJson(dbUserResponse);
          _currentUser = freshUser;
          await _saveSession(freshUser);
        } else {
          // User was deleted/no longer exists in DB, clear session
          _currentUser = null;
          await _clearSession();
        }
      } catch (dbError) {
        // Network or DB error: keep using cached localUser (fallback)
        debugPrint('DB session verification failed: $dbError. Falling back to local cache.');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch user from public.users table
      final response = await _supabase.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        throw 'User tidak ditemukan';
      }

      final hashedPasswordFromDb = response['password'] as String;

      // 2. Compare password using BCrypt
      final bool passwordMatches = BCrypt.checkpw(password, hashedPasswordFromDb);

      if (!passwordMatches) {
        throw 'Password salah';
      }

      // 3. Set custom session
      final user = UserModel.fromJson(response);
      _currentUser = user;
      await _saveSession(user);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    try {
      // 1. Check if user already exists
      final existingUser = await _supabase.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      }

      if (roleSlug == 'pasien' && supervisionCode != null && supervisionCode.isNotEmpty) {
        // Verify supervision code exists before creating user
        final supervision = await _supabase.client
            .from('supervisions')
            .select()
            .eq('supervision_code', supervisionCode)
            .maybeSingle();
        if (supervision == null) {
          throw 'Kode Pengawas tidak valid atau tidak ditemukan.';
        }
      }

      // 2. Hash password using BCrypt
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // 3. Insert into public.users
      final userResponse = await _supabase.client
          .from('users')
          .insert({
            'name': name,
            'email': email,
            'telephone_number': phone,
            'password': hashedPassword,
          })
          .select()
          .single();

      final userId = userResponse['id'] as int;

      // 4. Get role id from public.roles
      final roleResponse = await _supabase.client
          .from('roles')
          .select('id')
          .eq('slug', roleSlug)
          .single();
      final roleId = roleResponse['id'] as int;

      // 5. Insert into user_roles
      await _supabase.client.from('user_roles').insert({
        'user_id': userId,
        'role_id': roleId,
      });

      // 6. Handle Role specific logic
      if (roleSlug == 'pengawas') {
        // Generate unique supervision code e.g. TBC-XXXXXX
        final randomCode = 'TBC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}${DateTime.now().second}';
        await _supabase.client.from('supervisions').insert({
          'supervisor_id': userId,
          'supervision_code': randomCode,
        });
      } else if (roleSlug == 'pasien') {
        if (supervisionCode != null && supervisionCode.isNotEmpty) {
          final supervision = await _supabase.client
              .from('supervisions')
              .select('id')
              .eq('supervision_code', supervisionCode)
              .maybeSingle();
          if (supervision != null) {
            final supervisionId = supervision['id'] as int;
            await _supabase.client.from('supervisions_patients').insert({
              'supervision_id': supervisionId,
              'patients_id': userId,
              'status': 'pending',
            });
          }
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

      // 7. Set custom session
      final user = UserModel.fromJson(userResponse);
      _currentUser = user;
      await _saveSession(user);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
