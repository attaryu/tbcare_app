class NotificationModel {
  final String id;
  final int receiverId;
  final int? senderId;
  final String type; // e.g. medication_proof_submitted, etc.
  final String title;
  final String body;
  final int? relatedId;
  final String? relatedTable;
  final bool isRead;
  final DateTime createdAt;

  // Joined sender details for UI
  final String? senderName;
  final String? senderPhotoUrl;

  NotificationModel({
    required this.id,
    required this.receiverId,
    this.senderId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.relatedTable,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderPhotoUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      receiverId: json['receiver_id'] as int,
      senderId: json['sender_id'] as int?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedId: json['related_id'] as int?,
      relatedTable: json['related_table'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      senderName: json['sender']?['name'] as String?,
      senderPhotoUrl: json['sender']?['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': type,
      'title': title,
      'body': body,
      'related_id': relatedId,
      'related_table': relatedTable,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    int? receiverId,
    int? senderId,
    String? type,
    String? title,
    String? body,
    int? relatedId,
    String? relatedTable,
    bool? isRead,
    DateTime? createdAt,
    String? senderName,
    String? senderPhotoUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedId: relatedId ?? this.relatedId,
      relatedTable: relatedTable ?? this.relatedTable,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}
