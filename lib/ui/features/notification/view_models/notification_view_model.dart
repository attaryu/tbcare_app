import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/services/supabase_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;
  final int _userId;
  RealtimeChannel? _realtimeChannel;

  NotificationViewModel({
    required NotificationRepository repository,
    required int userId,
  })  : _repository = repository,
        _userId = userId {
    fetchNotifications();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _unsubscribeFromNotifications();
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.fetchNotifications(_userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead(_userId);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Subscribe to realtime inserts/updates on notifications table for receiver_id
  void _subscribeToNotifications() {
    try {
      final client = SupabaseService.instance.client;
      _realtimeChannel = client
          .channel('public:notifications:receiver_id=eq.$_userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'receiver_id',
              value: _userId,
            ),
            callback: (payload) {
              debugPrint('Realtime notification event: ${payload.eventType}');
              fetchNotifications();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Failed to setup notifications subscription: $e');
    }
  }

  void _unsubscribeFromNotifications() {
    if (_realtimeChannel != null) {
      SupabaseService.instance.client.removeChannel(_realtimeChannel!);
    }
  }
}
