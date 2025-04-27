import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<bool> checkAndroidPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      print('Android plugin not available');
      return false;
    }

    final granted = await androidPlugin.requestNotificationsPermission();
    if (granted == null || !granted) {
      print('Notification permissions not granted');
      return false;
    }

    final exactAlarmGranted =
        await androidPlugin.requestExactAlarmsPermission();
    if (exactAlarmGranted == null || !exactAlarmGranted) {
      print('Exact alarm permission not granted');
      return false;
    }

    return true;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    // Set local timezone
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    print('Creating notification channel...');
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vocable_channel',
      'Vocable Notifications',
      description: 'Notifications pour l\'apprentissage du vocabulaire',
      importance: Importance.max,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('Notification channel created successfully');
    } else {
      print('Android plugin not available');
    }

    _isInitialized = true;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
    int notificationId = 0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final hasPermissions = await checkAndroidPermissions();
    if (!hasPermissions) {
      return;
    }

    try {
      // Get current date and timezone info
      final now = tz.TZDateTime.now(tz.local);

      // Create scheduled time for the specified hour and minute
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Cancel only the specific notification if it exists
      await _notifications.cancel(notificationId);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'vocable_channel',
        'Vocable Notifications',
        channelDescription:
            'Notifications pour l\'apprentissage du vocabulaire',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        fullScreenIntent: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: DefaultStyleInformation(true, true),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder_$notificationId',
      );
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
