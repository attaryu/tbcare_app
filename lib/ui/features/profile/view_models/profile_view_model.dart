import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  final int _userId;

  ProfileViewModel({required ProfileRepository repository, required int userId})
      : _repository = repository,
        _userId = userId {
    fetchProfile();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  UserModel? _user;
  UserModel? get user => _user;

  String _roleSlug = 'pasien';
  String get roleSlug => _roleSlug;

  String _roleName = 'Pasien';
  String get roleName => _roleName;

  Map<String, dynamic>? _supervisorInfo;
  Map<String, dynamic>? get supervisorInfo => _supervisorInfo;

  Map<String, dynamic>? _treatmentPeriod;
  Map<String, dynamic>? get treatmentPeriod => _treatmentPeriod;

  List<Map<String, dynamic>> _medicationSchedules = [];
  List<Map<String, dynamic>> get medicationSchedules => _medicationSchedules;

  String? _supervisorCode;
  String? get supervisorCode => _supervisorCode;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getUserProfile(_userId);
      _user = data['user'] as UserModel;
      _roleSlug = data['roleSlug'] as String;
      _roleName = data['roleName'] as String;
      _supervisorInfo = data['supervisorInfo'] as Map<String, dynamic>?;
      _treatmentPeriod = data['treatmentPeriod'] as Map<String, dynamic>?;
      _medicationSchedules = data['medicationSchedules'] as List<Map<String, dynamic>>;
      _supervisorCode = data['supervisorCode'] as String?;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSupervisor(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.addSupervisor(_userId, code);
      await fetchProfile();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserProfile(String name, String? phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateUserProfile(_userId, name, phone);
      await fetchProfile();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
