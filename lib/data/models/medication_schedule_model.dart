class MedicationScheduleModel {
  final int id;
  final int treatmentPeriodId;
  final String medName;
  final String scheduleTime; // Format "HH:mm:ss" atau "HH:mm"

  MedicationScheduleModel({
    required this.id,
    required this.treatmentPeriodId,
    required this.medName,
    required this.scheduleTime,
  });

  factory MedicationScheduleModel.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleModel(
      id: json['id'],
      treatmentPeriodId: json['treatment_period_id'],
      medName: json['med_name'],
      scheduleTime: json['schedule_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'treatment_period_id': treatmentPeriodId,
      'med_name': medName,
      'schedule_time': scheduleTime,
    };
  }

  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'treatment_period_id': treatmentPeriodId,
      'med_name': medName,
      'schedule_time': scheduleTime,
    };
  }
}
