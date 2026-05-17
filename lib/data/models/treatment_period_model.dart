class TreatmentPeriodModel {
  final int id;
  final int patientsId;
  final String name;
  final DateTime startDate;
  final DateTime? actualEndDate;
  final DateTime? predictionEndDate;
  final int duration;
  final String durationType;
  final String status;

  TreatmentPeriodModel({
    required this.id,
    required this.patientsId,
    required this.name,
    required this.startDate,
    this.actualEndDate,
    this.predictionEndDate,
    required this.duration,
    required this.durationType,
    required this.status,
  });

  factory TreatmentPeriodModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPeriodModel(
      id: json['id'],
      patientsId: json['patients_id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      actualEndDate: json['actual_end_date'] != null
          ? DateTime.parse(json['actual_end_date'])
          : null,
      predictionEndDate: json['prediction_end_date'] != null
          ? DateTime.parse(json['prediction_end_date'])
          : null,
      duration: json['duration'],
      durationType: json['duration_type'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patients_id': patientsId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'actual_end_date': actualEndDate?.toIso8601String().split('T')[0],
      'prediction_end_date': predictionEndDate?.toIso8601String().split('T')[0],
      'duration': duration,
      'duration_type': durationType,
      'status': status,
    };
  }
}
