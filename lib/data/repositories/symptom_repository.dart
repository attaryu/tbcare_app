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

  /// Gets the active treatment period for a specific user ID
  Future<int?> getActiveTreatmentPeriodId(int userId) async {
    final tpResponse = await _supabase.client
        .from('treatment_periods')
        .select('id')
        .eq('patients_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    return tpResponse?['id'];
  }
}
