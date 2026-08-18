import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logger_service.dart';

/// Manages the daily "Good Morning + Verse of the Day" notification.
///
/// A repeating daily notification is scheduled for 7:00 AM local time. The
/// content (user name + verse) is refreshed every time the app is opened so
/// the verse shown matches the day it is delivered.
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  static const int _dailyVerseNotificationId = 1001;
  static const String _channelId = 'daily_verse_channel';
  static const String _channelName = 'Daily Verse';
  static const String _channelDescription =
      'Good Morning greeting with the Bible verse of the day';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes the plugin and creates the notification channel.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_book'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings: settings);
      _isInitialized = true;
      LoggerService.info('Notification service initialized');
    } catch (e) {
      LoggerService.error('Failed to initialize notifications: $e');
    }
  }

  /// Requests notification permission (Android 13+ and iOS).
  Future<bool?> requestPermissions() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final grantedAndroid = await android?.requestNotificationsPermission();
      final grantedIos =
          await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return grantedAndroid ?? grantedIos ?? true;
    } catch (e) {
      LoggerService.error('Notification permission request failed: $e');
      return false;
    }
  }

  /// Schedules (or re-schedules) the daily 7:00 AM verse notification.
  ///
  /// Re-scheduling with the same id replaces any previously scheduled
  /// notification, which keeps the verse content fresh for each day.
  Future<void> scheduleDailyVerse({
    required String userName,
    required String verseText,
    required String verseReference,
  }) async {
    try {
      await _configureLocalTimeZone();

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 7);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final title =
          userName.isEmpty ? 'Good Morning!' : 'Good Morning $userName!';
      final trimmedVerse = verseText.length > 400
          ? '${verseText.substring(0, 400)}...'
          : verseText;

      await _plugin.zonedSchedule(
        id: _dailyVerseNotificationId,
        title: title,
        body: '$trimmedVerse\n\n$verseReference',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'verse_of_the_day',
      );

      LoggerService.info('Daily verse notification scheduled for 7:00 AM');
    } catch (e) {
      LoggerService.error('Failed to schedule daily verse notification: $e');
    }
  }

  /// Cancels the scheduled daily verse notification.
  Future<void> cancelDailyVerse() async {
    try {
      await _plugin.cancel(id: _dailyVerseNotificationId);
    } catch (e) {
      LoggerService.error('Failed to cancel daily verse notification: $e');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      LoggerService.warning('Could not get local timezone: $e');
    }
  }
}
