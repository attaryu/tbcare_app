import 'package:flutter/material.dart';
import '../../../../data/repositories/supervisor_repository.dart';

class SupervisorViewModel extends ChangeNotifier {
  final SupervisorRepository _repository;
  final int _supervisorId;

  SupervisorViewModel({
    required SupervisorRepository repository,
    required int supervisorId,
  })  : _repository = repository,
        _supervisorId = supervisorId {
    loadData();
  }

  String? _supervisorCode;
  String? get supervisorCode => _supervisorCode;

  List<Map<String, dynamic>> _joinRequests = [];
  List<Map<String, dynamic>> get joinRequests => _joinRequests;

  List<Map<String, dynamic>> _approvedPatients = [];
  List<Map<String, dynamic>> get approvedPatients => _approvedPatients;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _supervisorCode = await _repository.getSupervisorCode(_supervisorId);
      _joinRequests = await _repository.getJoinRequests(_supervisorId);
      _approvedPatients = await _repository.getApprovedPatients(_supervisorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(int relationshipId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.acceptJoinRequest(relationshipId);
      await loadData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectRequest(int relationshipId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.rejectJoinRequest(relationshipId);
      await loadData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePatient(int relationshipId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.removePatient(relationshipId);
      await loadData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
