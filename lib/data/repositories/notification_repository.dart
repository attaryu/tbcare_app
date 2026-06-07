import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationRepository {
  final SupabaseService _supabase;

  NotificationRepository(this._supabase);

  /// Fetch notifications for a specific receiver (patient or supervisor)
  Future<List<NotificationModel>> fetchNotifications(int receiverId) async {
    try {
      final res = await _supabase.client
          .from('notifications')
          .select('*, sender:users!notifications_sender_id_fkey(name, photo_url)')
          .eq('receiver_id', receiverId)
          .order('created_at', ascending: false);
      
      return (res as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a specific receiver
  Future<void> markAllAsRead(int receiverId) async {
    try {
      await _supabase.client
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', receiverId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Trigger sending of a push notification and DB insertion by calling Edge Function
  Future<void> sendNotification({
    required int receiverId,
    int? senderId,
    required String type,
    required String title,
    required String body,
    int? relatedId,
    String? relatedTable,
  }) async {
    try {
      await _supabase.client.functions.invoke(
        'send-notification',
        body: {
          'receiver_id': receiverId,
          'sender_id': senderId,
          'type': type,
          'title': title,
          'body': body,
          'related_id': relatedId,
          'related_table': relatedTable,
        },
      );
    } catch (e) {
      debugPrint('Error invoking send-notification Edge Function: $e');
      
      // Fallback: insert directly to the DB so the user still receives it in the app's notification center
      // even if push delivery fails or Edge Function is not deployed.
      try {
        await _supabase.client.from('notifications').insert({
          'receiver_id': receiverId,
          'sender_id': senderId,
          'type': type,
          'title': title,
          'body': body,
          'related_id': relatedId,
          'related_table': relatedTable,
        });
        debugPrint('Direct insertion fallback succeeded for notification.');
      } catch (dbErr) {
        debugPrint('Direct insertion fallback also failed: $dbErr');
        rethrow;
      }
    }
  }
}
