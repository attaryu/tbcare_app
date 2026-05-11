import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseService _supabase;

  AuthViewModel(this._supabase);

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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
      _currentUser = UserModel.fromJson(response);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
