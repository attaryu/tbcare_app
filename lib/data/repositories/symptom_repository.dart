import '../models/symptom_model.dart';
import '../services/supabase_service.dart';

class SymptomRepository {
  final SupabaseService _supabase;

  SymptomRepository(this._supabase);

  Future<List<SymptomLog>> getSymptomLogs(int treatmentPeriodId) async {
    final response = await _supabase.client
        .from('symptom_logs')
        .select()
        .eq('treatment_period_id', treatmentPeriodId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => SymptomLog.fromJson(json)).toList();
  }

  Future<List<SymptomLog>> getSymptomLogsByDate(int treatmentPeriodId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final nextDay = date.add(const Duration(days: 1)).toIso8601String().split('T')[0];

    final response = await _supabase.client
        .from('symptom_logs')
        .select()
        .eq('treatment_period_id', treatmentPeriodId)
        .gte('created_at', '${dateStr}T00:00:00')
        .lt('created_at', '${nextDay}T00:00:00')
        .order('created_at', ascending: false);

    return (response as List).map((json) => SymptomLog.fromJson(json)).toList();
  }

  Future<void> addSymptomLog(SymptomLog log) async {
    await _supabase.client.from('symptom_logs').insert(log.toJson());
  }

  Future<void> updateSymptomLog(SymptomLog log) async {
    await _supabase.client
        .from('symptom_logs')
        .update(log.toJson()..['edited_at'] = DateTime.now().toIso8601String())
        .eq('id', log.id);
  }

  Future<void> deleteSymptomLog(int id) async {
    await _supabase.client.from('symptom_logs').delete().eq('id', id);
  }

  /// Gets the active treatment period for a specific user ID safely using list
  Future<int?> getActiveTreatmentPeriodId(int userId) async {
    final tpList = await _supabase.client
        .from('treatment_periods')
        .select('id')
        .eq('patients_id', userId)
        .eq('status', 'active');

    if (tpList.isNotEmpty) {
      return tpList.first['id'] as int;
    }
    return null;
  }
}
