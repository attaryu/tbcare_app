import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppAlarmService {
  static final AppAlarmService _instance = AppAlarmService._internal();
  factory AppAlarmService() => _instance;
  AppAlarmService._internal();

  /// Stream subscription for alarm rings
  static StreamSubscription<AlarmSet>? _ringSubscription;
  static Function(AlarmSettings)? _onAlarmRing;
  static Set<int> _previouslyRingingIds = {};

  /// Initialize the service and start listening to the ring stream
  static void init() {
    _ringSubscription?.cancel();
    _ringSubscription = Alarm.ringing.listen((alarmSet) {
      final currentRinging = alarmSet.alarms;
      for (final alarm in currentRinging) {
        if (!_previouslyRingingIds.contains(alarm.id)) {
          debugPrint('Alarm ringing for schedule: ${alarm.id}');
          if (_onAlarmRing != null) {
            _onAlarmRing!(alarm);
          }
        }
      }
      _previouslyRingingIds = currentRinging.map((e) => e.id).toSet();
    });
  }

  /// Set the callback for when an alarm rings
  static void setAlarmRingCallback(Function(AlarmSettings) callback) {
    _onAlarmRing = callback;
  }

  /// Clear the callback
  static void clearAlarmRingCallback() {
    _onAlarmRing = null;
  }

  /// Check and request necessary permissions
  static Future<bool> requestPermissions() async {
    final statusNotification = await Permission.notification.status;
    if (statusNotification.isDenied) {
      await Permission.notification.request();
    }

    final statusAlarm = await Permission.scheduleExactAlarm.status;
    if (statusAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    return (await Permission.notification.isGranted || await Permission.notification.isLimited) &&
        (await Permission.scheduleExactAlarm.isGranted || await Permission.scheduleExactAlarm.isLimited);
  }

  /// Cancel alarm for a specific schedule
  static Future<void> cancelAlarmForSchedule(int scheduleId) async {
    // Cancel both today (dayOffset = 0) and tomorrow (dayOffset = 1)
    await Alarm.stop(scheduleId * 10);
    await Alarm.stop((scheduleId * 10) + 1);
    debugPrint('Alarms cancelled for schedule ID: $scheduleId');
  }

  /// Sync alarms with current active schedules
  static Future<void> syncAlarmsWithSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('Alarm permissions not fully granted. Sync skipped.');
        return;
      }

      final activeAlarms = await Alarm.getAlarms();
      final activeAlarmIds = activeAlarms.map((e) => e.id).toSet();

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      // Keep track of which alarm IDs should be active
      final targetAlarmIds = <int>{};

      for (final sched in schedules) {
        final scheduleId = sched['id'] as int;
        final medName = sched['med_name'] as String? ?? 'Obat TBC';
        final timeStr = sched['schedule_time'] as String?;
        if (timeStr == null || timeStr.isEmpty) continue;

        // format is HH:mm:ss or HH:mm, extract HH:mm
        final timePart = timeStr.substring(0, 5);

        // Check Status Today
        final todayStatus = sched['today_status'] as String? ?? 'Segera';
        final todayAlarmId = scheduleId * 10;

        if (todayStatus == 'Segera') {
          final todaySchedTime = DateTime.tryParse('${todayStr}T$timePart:00');
          if (todaySchedTime != null) {
            // Only set if the time is in the future
            if (todaySchedTime.isAfter(now)) {
              targetAlarmIds.add(todayAlarmId);
              if (!activeAlarmIds.contains(todayAlarmId)) {
                await _setMedAlarm(
                  id: todayAlarmId,
                  time: todaySchedTime,
                  medName: medName,
                  timeStr: timePart,
                );
              }
            }
          }
        }

        // Set Tomorrow Alarm
        final tomorrowAlarmId = (scheduleId * 10) + 1;
        final tomorrowSchedTime = DateTime.tryParse('${tomorrowStr}T$timePart:00');
        if (tomorrowSchedTime != null) {
          targetAlarmIds.add(tomorrowAlarmId);
          if (!activeAlarmIds.contains(tomorrowAlarmId)) {
            await _setMedAlarm(
              id: tomorrowAlarmId,
              time: tomorrowSchedTime,
              medName: medName,
              timeStr: timePart,
            );
          }
        }
      }

      // Cleanup alarms that are no longer in the targets (e.g. deleted schedules or already taken)
      for (final alarm in activeAlarms) {
        // Only cancel alarms that belong to the rolling schedule system (e.g. ids like scheduleId*10 or scheduleId*10 + 1)
        // Skip user test alarm (like 999) if any
        if (alarm.id == 999) continue;

        if (!targetAlarmIds.contains(alarm.id)) {
          await Alarm.stop(alarm.id);
          debugPrint('Obsolete alarm stopped: ${alarm.id}');
        }
      }
    } catch (e) {
      debugPrint('Error syncing alarms: $e');
    }
  }

  static Future<void> _setMedAlarm({
    required int id,
    required DateTime time,
    required String medName,
    required String timeStr,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: time,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: const VolumeSettings.fixed(
        // volume: 1.0,
        volume: 0.5, // test
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Waktunya Minum Obat!',
        body: 'Ambil obat $medName ($timeStr WIB) sekarang.',
        stopButton: 'Matikan Alarm',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    debugPrint('Scheduled alarm $id for $medName at $time');
  }
}
