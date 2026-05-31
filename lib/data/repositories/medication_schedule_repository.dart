import '../models/compliance_log_model.dart';
import '../models/medication_schedule_model.dart';
import '../services/supabase_service.dart';

class MedicationScheduleRepository {
  final SupabaseService _supabase;

  MedicationScheduleRepository(this._supabase);

  Future<Map<String, dynamic>?> getActiveTreatmentPeriod(int userId) async {
    final res = await _supabase.client
        .from('treatment_periods')
        .select()
        .eq('patients_id', userId)
        .eq('status', 'active');

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<List<MedicationScheduleModel>> getMedicationSchedules(int treatmentPeriodId) async {
    final res = await _supabase.client
        .from('medication_schedules')
        .select()
        .eq('treatment_period_id', treatmentPeriodId)
        .order('schedule_time');

    return (res as List).map((json) => MedicationScheduleModel.fromJson(json)).toList();
  }

  Future<void> addMedicationSchedule(MedicationScheduleModel schedule) async {
    await _supabase.client.from('medication_schedules').insert(schedule.toJson());
  }

  Future<void> updateMedicationSchedule(int id, String medName, String scheduleTime) async {
    await _supabase.client
        .from('medication_schedules')
        .update({
          'med_name': medName,
          'schedule_time': scheduleTime,
        })
        .eq('id', id);
  }

  Future<void> deleteMedicationSchedule(int id) async {
    await _supabase.client.from('medication_schedules').delete().eq('id', id);
  }
}
