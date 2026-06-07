import '../models/treatment_period_model.dart';
import '../services/supabase_service.dart';

class TreatmentRepository {
  final SupabaseService _supabase;

  TreatmentRepository(this._supabase);

  Future<List<TreatmentPeriodModel>> getTreatmentPeriods(int userId) async {
    final res = await _supabase.client
        .from('treatment_periods')
        .select()
        .eq('patients_id', userId)
        .order('start_date', ascending: false);

    return (res as List).map((json) => TreatmentPeriodModel.fromJson(json)).toList();
  }

  Future<double> getCompliancePercentage(int treatmentPeriodId) async {
    try {
      final schedRes = await _supabase.client
          .from('medication_schedules')
          .select('id')
          .eq('treatment_period_id', treatmentPeriodId);

      if (schedRes.isEmpty) return 0.0;

      final scheduleIds = (schedRes as List).map((e) => e['id'] as int).toList();

      final complianceRes = await _supabase.client
          .from('compliance_logs')
          .select('status')
          .inFilter('schedule_id', scheduleIds);

      if (complianceRes.isEmpty) return 0.0;

      int taken = 0;
      for (var log in complianceRes) {
        if (log['status'] == 'taken') taken++;
      }

      return (taken / complianceRes.length) * 100.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> markPeriodCompleted(int periodId) async {
    await _supabase.client
        .from('treatment_periods')
        .update({
          'status': 'completed',
          'actual_end_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('id', periodId);
  }

  Future<void> createTreatmentPeriod(
    int userId,
    String name,
    DateTime startDate,
    DateTime predictionEndDate,
    int duration,
    String durationType,
  ) async {
    await _supabase.client
        .from('treatment_periods')
        .update({
          'status': 'completed',
          'actual_end_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('patients_id', userId)
        .eq('status', 'active');

    await _supabase.client.from('treatment_periods').insert({
      'patients_id': userId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'prediction_end_date': predictionEndDate.toIso8601String().split('T')[0],
      'duration': duration,
      'duration_type': durationType,
      'status': 'active',
    });
  }

  Future<void> updateTreatmentPeriod(
    int periodId,
    String name,
    int duration,
    String durationType,
    DateTime predictionEndDate,
  ) async {
    await _supabase.client
        .from('treatment_periods')
        .update({
          'name': name,
          'duration': duration,
          'duration_type': durationType,
          'prediction_end_date': predictionEndDate.toIso8601String().split('T')[0],
        })
        .eq('id', periodId);
  }
}
