class ComplianceLogModel {
  final int id;
  final int scheduleId;
  final String medName;
  final String? photoUrl;
  final DateTime? takenAt;
  final String status; // 'pending' | 'taken' | 'missed'
  final int? verifiedBy;
  final DateTime logDate;

  ComplianceLogModel({
    required this.id,
    required this.scheduleId,
    required this.medName,
    this.photoUrl,
    this.takenAt,
    required this.status,
    this.verifiedBy,
    required this.logDate,
  });

  factory ComplianceLogModel.fromJson(Map<String, dynamic> json) {
    return ComplianceLogModel(
      id: json['id'] as int,
      scheduleId: json['schedule_id'] as int,
      medName: json['med_name'] as String,
      photoUrl: json['photo_url'] as String?,
      takenAt: json['taken_at'] != null ? DateTime.parse(json['taken_at'] as String).toLocal() : null,
      status: json['status'] as String,
      verifiedBy: json['verified_by'] as int?,
      logDate: DateTime.parse(json['log_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'med_name': medName,
      'photo_url': photoUrl,
      'taken_at': takenAt?.toUtc().toIso8601String(),
      'status': status,
      'verified_by': verifiedBy,
      'log_date': "${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}",
    };
  }

  Map<String, dynamic> toJsonWithId() {
    final map = toJson();
    map['id'] = id;
    return map;
  }
}
