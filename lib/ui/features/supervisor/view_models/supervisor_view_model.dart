import 'package:flutter/material.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/repositories/supervisor_repository.dart';
import '../../../../data/services/supabase_service.dart';

class SupervisorViewModel extends ChangeNotifier {
  final SupervisorRepository _repository;
  final NotificationRepository _notificationRepository;
  final int _supervisorId;

  SupervisorViewModel({
    required SupervisorRepository repository,
    required NotificationRepository notificationRepository,
    required int supervisorId,
  })  : _repository = repository,
        _notificationRepository = notificationRepository,
        _supervisorId = supervisorId {
    loadData();
  }

  String? _supervisorCode;
  String? get supervisorCode => _supervisorCode;

  List<Map<String, dynamic>> _joinRequests = [];
  List<Map<String, dynamic>> get joinRequests => _joinRequests;

  List<Map<String, dynamic>> _approvedPatients = [];
  List<Map<String, dynamic>> get approvedPatients => _approvedPatients;

  List<Map<String, dynamic>> _terlewatList = [];
  List<Map<String, dynamic>> get terlewatList => _terlewatList;

  List<Map<String, dynamic>> _verifikasiList = [];
  List<Map<String, dynamic>> get verifikasiList => _verifikasiList;

  List<Map<String, dynamic>> _amanList = [];
  List<Map<String, dynamic>> get amanList => _amanList;

  int get terlewatCount => _terlewatList.length;
  int get verifikasiCount => _verifikasiList.length;
  int get amanCount => _amanList.length;

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
      await _loadDailySummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDailySummary() async {
    final summary = await _repository.getDailyPatientSummary(_supervisorId);
    _terlewatList = summary.where((s) => s['category'] == 'terlewat').toList();
    _verifikasiList = summary.where((s) => s['category'] == 'butuh_verifikasi').toList();
    _amanList = summary.where((s) => s['category'] == 'aman').toList();
  }

  Future<void> acceptRequest(int relationshipId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch relationship info to get patient_id
      final relRes = await SupabaseService.instance.client
          .from('supervisions_patients')
          .select('patients_id')
          .eq('id', relationshipId)
          .maybeSingle();

      await _repository.acceptJoinRequest(relationshipId);
      await loadData();

      if (relRes != null && relRes['patients_id'] != null) {
        final patientId = relRes['patients_id'] as int;
        await _notificationRepository.sendNotification(
          receiverId: patientId,
          senderId: _supervisorId,
          type: 'supervision_accepted',
          title: 'Permintaan Diterima',
          body: 'Pengawas telah menyetujui permintaan Anda untuk terhubung.',
          relatedId: _supervisorId,
          relatedTable: 'users',
        );
      }
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
      // Fetch relationship info to get patient_id
      final relRes = await SupabaseService.instance.client
          .from('supervisions_patients')
          .select('patients_id')
          .eq('id', relationshipId)
          .maybeSingle();

      await _repository.rejectJoinRequest(relationshipId);
      await loadData();

      if (relRes != null && relRes['patients_id'] != null) {
        final patientId = relRes['patients_id'] as int;
        await _notificationRepository.sendNotification(
          receiverId: patientId,
          senderId: _supervisorId,
          type: 'supervision_rejected',
          title: 'Permintaan Ditolak',
          body: 'Pengawas telah menolak permintaan Anda untuk terhubung.',
          relatedId: _supervisorId,
          relatedTable: 'users',
        );
      }
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

  Future<void> verifyLog(int logId) async {
    // We need to fetch the log details (schedule_id -> treatment_period_id -> patient_id) to notify the correct receiver.
    try {
      final logRes = await SupabaseService.instance.client
          .from('compliance_logs')
          .select('id, schedule:medication_schedules(med_name, schedule_time, treatment_period:treatment_periods(patients_id))')
          .eq('id', logId)
          .maybeSingle();

      await _repository.verifyComplianceLog(logId, _supervisorId);
      await _loadDailySummary();
      notifyListeners();

      if (logRes != null) {
        final schedule = logRes['schedule'] as Map<String, dynamic>?;
        if (schedule != null) {
          final medName = schedule['med_name'] as String? ?? 'Obat TBC';
          final scheduleTime = schedule['schedule_time'] as String? ?? '';
          final treatmentPeriod = schedule['treatment_period'] as Map<String, dynamic>?;
          if (treatmentPeriod != null && treatmentPeriod['patients_id'] != null) {
            final patientId = treatmentPeriod['patients_id'] as int;
            await _notificationRepository.sendNotification(
              receiverId: patientId,
              senderId: _supervisorId,
              type: 'medication_proof_confirmed',
              title: 'Bukti Minum Obat Disetujui',
              body: 'Bukti minum obat Anda untuk $medName ($scheduleTime) telah disetujui oleh Pengawas.',
              relatedId: logId,
              relatedTable: 'compliance_logs',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending confirmation notification: $e');
    }
  }

  Future<void> rejectLog(int logId, String scheduleTime) async {
    try {
      final logRes = await SupabaseService.instance.client
          .from('compliance_logs')
          .select('id, schedule:medication_schedules(med_name, treatment_period:treatment_periods(patients_id))')
          .eq('id', logId)
          .maybeSingle();

      await _repository.rejectComplianceLog(logId, scheduleTime);
      await _loadDailySummary();
      notifyListeners();

      if (logRes != null) {
        final schedule = logRes['schedule'] as Map<String, dynamic>?;
        if (schedule != null) {
          final medName = schedule['med_name'] as String? ?? 'Obat TBC';
          final treatmentPeriod = schedule['treatment_period'] as Map<String, dynamic>?;
          if (treatmentPeriod != null && treatmentPeriod['patients_id'] != null) {
            final patientId = treatmentPeriod['patients_id'] as int;
            await _notificationRepository.sendNotification(
              receiverId: patientId,
              senderId: _supervisorId,
              type: 'medication_proof_rejected',
              title: 'Bukti Minum Obat Ditolak',
              body: 'Bukti minum obat Anda untuk $medName ($scheduleTime) telah ditolak oleh Pengawas. Silakan unggah bukti ulang.',
              relatedId: logId,
              relatedTable: 'compliance_logs',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending rejection notification: $e');
    }
  }

  Future<void> ignoreEscalation(int escalationId) async {
    await _repository.ignoreEscalation(escalationId, _supervisorId);
    await _loadDailySummary();
    notifyListeners();
  }
}
