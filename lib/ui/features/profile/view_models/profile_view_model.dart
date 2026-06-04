import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/profile_repository.dart';

enum ProfileMenuAction {
  editProfile,
  viewSupervisor,
  addSupervisor,
  treatmentPeriod,
  medicationSchedule,
  logout,
}

class ProfileMenuItem {
  final String title;
  final IconData icon;
  final ProfileMenuAction action;
  final bool isDestructive;

  const ProfileMenuItem({
    required this.title,
    required this.icon,
    required this.action,
    this.isDestructive = false,
  });
}

class ProfileMenuSection {
  final String title;
  final List<ProfileMenuItem> items;

  const ProfileMenuSection({
    required this.title,
    required this.items,
  });
}

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

  String _roleSlug = '';
  String get roleSlug => _roleSlug;

  String _roleName = '';
  String get roleName => _roleName;

  Map<String, dynamic>? _supervisorInfo;
  Map<String, dynamic>? get supervisorInfo => _supervisorInfo;

  Map<String, dynamic>? _treatmentPeriod;
  Map<String, dynamic>? get treatmentPeriod => _treatmentPeriod;

  List<Map<String, dynamic>> _medicationSchedules = [];
  List<Map<String, dynamic>> get medicationSchedules => _medicationSchedules;

  String? _supervisorCode;
  String? get supervisorCode => _supervisorCode;

  List<ProfileMenuSection> get menuSections {
    final sections = <ProfileMenuSection>[];

    // Akun Section
    final accountItems = <ProfileMenuItem>[
      const ProfileMenuItem(
        title: 'Edit Profil',
        icon: Icons.person_outline,
        action: ProfileMenuAction.editProfile,
      ),
    ];

    if (_roleSlug == 'pasien') {
      if (_supervisorInfo != null) {
        accountItems.add(const ProfileMenuItem(
          title: 'Lihat Pengawas',
          icon: Icons.people_outline,
          action: ProfileMenuAction.viewSupervisor,
        ));
      } else {
        accountItems.add(const ProfileMenuItem(
          title: 'Tambah Pengawas',
          icon: Icons.shield_outlined,
          action: ProfileMenuAction.addSupervisor,
        ));
      }
    }

    sections.add(ProfileMenuSection(
      title: 'Akun',
      items: accountItems,
    ));

    // Informasi Pengobatan Section
    if (_roleSlug == 'pasien') {
      sections.add(const ProfileMenuSection(
        title: 'Informasi Pengobatan',
        items: [
          ProfileMenuItem(
            title: 'Periode Pengobatan',
            icon: Icons.calendar_today_outlined,
            action: ProfileMenuAction.treatmentPeriod,
          ),
          ProfileMenuItem(
            title: 'Jadwal Minum Obat Harian',
            icon: Icons.alarm,
            action: ProfileMenuAction.medicationSchedule,
          ),
        ],
      ));
    }

    // Lainnya Section (Logout)
    sections.add(const ProfileMenuSection(
      title: 'Lainnya',
      items: [
        ProfileMenuItem(
          title: 'Keluar Akun',
          icon: Icons.logout_outlined,
          action: ProfileMenuAction.logout,
          isDestructive: true,
        ),
      ],
    ));

    return sections;
  }

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
