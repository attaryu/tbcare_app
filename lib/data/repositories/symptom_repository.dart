import '../models/symptom_model.dart';
import '../services/supabase_service.dart';

class SymptomRepository {
  final SupabaseService _supabase;

  SymptomRepository(this._supabase);

  Future<List<SymptomLog>> getSymptomLogs(int treatmentPeriodId) async {
    var response = await _supabase.client
        .from('symptom_logs')
        .select()
        .eq('treatment_period_id', treatmentPeriodId)
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      final note =
          "Lorem ipsum elementum malesuada feugiat tempus rhoncus sit habitant elit justo lectus non in arcu fringilla porta malesuada amet mus ultrices leo urna elementum.";
      final now = DateTime.now();

      final logsToInsert = [
        {
          'treatment_period_id': treatmentPeriodId,
          'level': 'mild',
          'note': note,
          'created_at': DateTime(now.year, now.month, 20, 13, 20).toIso8601String(),
        },
        {
          'treatment_period_id': treatmentPeriodId,
          'level': 'severe',
          'note': note,
          'created_at': DateTime(now.year, now.month, 16, 20, 20).toIso8601String(),
        },
        {
          'treatment_period_id': treatmentPeriodId,
          'level': 'normal',
          'note': note,
          'created_at': DateTime(now.year, now.month, 14, 4, 20).toIso8601String(),
        },
        {
          'treatment_period_id': treatmentPeriodId,
          'level': 'mild',
          'note': note,
          'created_at': DateTime(now.year, now.month, 12, 18, 20).toIso8601String(),
        },
      ];

      await _supabase.client.from('symptom_logs').insert(logsToInsert);

      response = await _supabase.client
          .from('symptom_logs')
          .select()
          .eq('treatment_period_id', treatmentPeriodId)
          .order('created_at', ascending: false);
    }

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
