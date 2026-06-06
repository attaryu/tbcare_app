import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppAlarmService {
  static final AppAlarmService _instance = AppAlarmService._internal();
  factory AppAlarmService() => _instance;
  AppAlarmService._internal();

  static const List<int> _countdownOffsets = [-10, -8, -5, -4, -3, -2, -1, 0];

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
    // Cancel all 16 alarms (8 today + 8 tomorrow) for this schedule
    for (int i = 0; i < 16; i++) {
      await Alarm.stop((scheduleId * 20) + i);
    }
    debugPrint('Alarms cancelled for schedule ID: $scheduleId');
  }

  /// Cancel ALL active alarms (called on logout)
  static Future<void> cancelAllAlarms() async {
    try {
      final activeAlarms = await Alarm.getAlarms();
      for (final alarm in activeAlarms) {
        await Alarm.stop(alarm.id);
      }
      debugPrint('All alarms cancelled (logout).');
    } catch (e) {
      debugPrint('Error cancelling all alarms: $e');
    }
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

        if (todayStatus == 'Segera') {
          final todaySchedTime = DateTime.tryParse('${todayStr}T$timePart:00');
          if (todaySchedTime != null) {
            for (int i = 0; i < _countdownOffsets.length; i++) {
              final offset = _countdownOffsets[i];
              final alarmId = (scheduleId * 20) + i;
              final alarmTime = todaySchedTime.add(Duration(minutes: offset));

              if (alarmTime.isAfter(now)) {
                targetAlarmIds.add(alarmId);
                if (!activeAlarmIds.contains(alarmId)) {
                  final loop = (offset == 0);
                  final bodyText = (offset == 0)
                      ? 'Ambil obat $medName ($timePart WIB) sekarang!'
                      : 'Persiapkan obat $medName - jadwal minum ${offset.abs()} menit lagi ($timePart WIB).';
                  await _setMedAlarm(
                    id: alarmId,
                    time: alarmTime,
                    medName: medName,
                    timeStr: timePart,
                    bodyText: bodyText,
                    loopAudio: loop,
                  );
                }
              }
            }
          }
        }

        // Set Tomorrow Alarms
        final tomorrowSchedTime = DateTime.tryParse('${tomorrowStr}T$timePart:00');
        if (tomorrowSchedTime != null) {
          for (int i = 0; i < _countdownOffsets.length; i++) {
            final offset = _countdownOffsets[i];
            final alarmId = (scheduleId * 20) + 8 + i;
            final alarmTime = tomorrowSchedTime.add(Duration(minutes: offset));

            targetAlarmIds.add(alarmId);
            if (!activeAlarmIds.contains(alarmId)) {
              final loop = (offset == 0);
              final bodyText = (offset == 0)
                  ? 'Ambil obat $medName ($timePart WIB) sekarang!'
                  : 'Persiapkan obat $medName - jadwal minum ${offset.abs()} menit lagi ($timePart WIB).';
              await _setMedAlarm(
                id: alarmId,
                time: alarmTime,
                medName: medName,
                timeStr: timePart,
                bodyText: bodyText,
                loopAudio: loop,
              );
            }
          }
        }
      }

      // Cleanup alarms that are no longer in the targets (e.g. deleted schedules or already taken)
      for (final alarm in activeAlarms) {
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
    required String bodyText,
    required bool loopAudio,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: time,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: loopAudio,
      vibrate: true,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: const VolumeSettings.fixed(
        volume: 0.5,
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Waktunya Minum Obat!',
        body: bodyText,
        stopButton: 'Matikan Alarm',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    debugPrint('Scheduled alarm $id for $medName at $time with body: "$bodyText" (loop: $loopAudio)');
  }
}
