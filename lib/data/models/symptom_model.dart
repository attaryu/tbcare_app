enum SymptomLevel {
  normal,
  mild,
  severe;

  String get displayName {
    switch (this) {
      case SymptomLevel.normal:
        return 'Normal';
      case SymptomLevel.mild:
        return 'Ringan';
      case SymptomLevel.severe:
        return 'Parah';
    }
  }
}

class SymptomLog {
  final int id;
  final int treatmentPeriodId;
  final SymptomLevel level;
  final String? note;
  final DateTime createdAt;
  final DateTime? editedAt;

  SymptomLog({
    required this.id,
    required this.treatmentPeriodId,
    required this.level,
    this.note,
    required this.createdAt,
    this.editedAt,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'],
      treatmentPeriodId: json['treatment_period_id'],
      level: SymptomLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => SymptomLevel.normal,
      ),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'treatment_period_id': treatmentPeriodId,
      'level': level.name,
      'note': note,
      'created_at': createdAt.toUtc().toIso8601String(),
      'edited_at': editedAt?.toUtc().toIso8601String(),
    };
  }

  SymptomLog copyWith({
    int? treatmentPeriodId,
    SymptomLevel? level,
    String? note,
    DateTime? editedAt,
  }) {
    return SymptomLog(
      id: id,
      treatmentPeriodId: treatmentPeriodId ?? this.treatmentPeriodId,
      level: level ?? this.level,
      note: note ?? this.note,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
