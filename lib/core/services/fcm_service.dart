import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  FcmService._privateConstructor();
  static final FcmService instance = FcmService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Initialize FCM permissions and listeners
  Future<void> init() async {
    try {
      // Request notifications permission (especially for Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      // Set options to show notifications even when the app is in the foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, 
        badge: true,
        sound: true,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen for foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Foreground message received:');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
        debugPrint('Data: ${message.data}');
      });

      // Handle user tapping the notification when the app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM: Notification clicked to open app: ${message.data}');
      });

    } catch (e) {
      debugPrint('Error initializing FcmService: $e');
    }
  }

  /// Get the current registration token for the device
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
      return null;
    }
  }

  /// Save/Update the device's token in Supabase
  Future<void> saveTokenToDatabase(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('FCM: Could not obtain token to save.');
        return;
      }
      
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);
          
      debugPrint('FCM Token successfully stored/updated in DB for User $userId: $token');
    } catch (e) {
      debugPrint('Error updating FCM Token in DB: $e');
    }
  }

  /// Clear the token on logout or session end
  Future<void> clearTokenFromDatabase(int userId) async {
    try {
      await _supabase
          .from('users')
          .update({'fcm_token': null})
          .eq('id', userId);
      debugPrint('FCM Token cleared in DB for User $userId');
    } catch (e) {
      debugPrint('Error clearing FCM Token in DB: $e');
    }
  }
}
