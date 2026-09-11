import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  bool openedFromNotification = false;
  Future<void> initialize(void Function() onTap) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onTap(),
    );
    openedFromNotification =
        (await plugin.getNotificationAppLaunchDetails())
            ?.didNotificationLaunchApp ??
        false;
    ready = true;
  }

  Future<bool> schedule(
    int hour,
    int minute, {
    required bool en,
    bool request = true,
  }) async {
    if (!ready) return false;
    if (request) {
      final granted = Platform.isAndroid
          ? await plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission()
          : await plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true);
      if (granted != true) return false;
    }
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    await plugin.zonedSchedule(
      id: 1,
      title: en ? 'What did you dream about?' : 'Что тебе приснилось?',
      body: en
          ? 'Save a little piece of the night.'
          : 'Сохрани маленький фрагмент этой ночи.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning',
          'DreamSpace',
          channelDescription: 'Morning dream journal reminder',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'record',
    );
    return true;
  }

  Future<void> cancel() async {
    if (ready) await plugin.cancel(id: 1);
  }
}

final reminders = ReminderService();
