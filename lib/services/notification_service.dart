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
      description: 'Notifications for vocabulary learning',
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

  Future<void> sendTestNotification() async {
    print('=== Starting test notification ===');

    if (!_isInitialized) {
      print('Service not initialized, initializing now...');
      await initialize();
    }

    final hasPermissions = await checkAndroidPermissions();
    if (!hasPermissions) {
      print('Permissions not granted, cannot send notification');
      return;
    }

    try {
      print('Creating notification details...');
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'vocable_channel',
        'Vocable Notifications',
        channelDescription: 'Notifications for vocabulary learning',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        fullScreenIntent: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: const DefaultStyleInformation(true, true),
      );

      print('Sending notification...');
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification from Vocable',
        const NotificationDetails(android: androidDetails),
        payload: 'test_notification',
      );
      print('Test notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
    }
    print('=== Test notification completed ===');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime now, {int secondsToAdd = 0}) {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second + secondsToAdd,
    );

    if (scheduledDate.isBefore(now)) {
      return scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleNotificationIn10Seconds() async {
    print('=== Scheduling notification in 10 seconds ===');

    if (!_isInitialized) {
      print('Service not initialized, initializing now...');
      await initialize();
    }

    final hasPermissions = await checkAndroidPermissions();
    if (!hasPermissions) {
      print('Permissions not granted, cannot schedule notification');
      return;
    }

    try {
      // Get current time and add 10 seconds
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = _nextInstanceOfTime(now, secondsToAdd: 10);
      print('Current time: ${now.toString()}');
      print('Scheduled time: ${scheduledTime.toString()}');
      print(
          'Time difference: ${scheduledTime.difference(now).inSeconds} seconds');

      // First cancel any existing notification with the same ID
      await _notifications.cancel(1010);
      print('Cancelled any existing notification with ID 1010');

      print('Creating notification details...');
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'vocable_channel',
        'Vocable Notifications',
        channelDescription: 'Notifications for vocabulary learning',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
        fullScreenIntent: true,
        ongoing: false,
        styleInformation: const DefaultStyleInformation(true, true),
      );

      print('Scheduling notification...');
      await _notifications.zonedSchedule(
        1010, // Unique ID for this notification
        'Test Notification',
        'Notification programmée pour ${scheduledTime.toString()}',
        scheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'test_notification_10s',
      );

      print('Notification scheduled successfully');
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
    }
    print('=== Notification scheduling completed ===');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cleanUpScheduledNotifications() async {
    print('=== Cleaning up scheduled notifications ===');
    try {
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      print('Found ${pendingNotifications.length} pending notifications');

      for (var notification in pendingNotifications) {
        print('Cancelling notification ID: ${notification.id}');
        await _notifications.cancel(notification.id);
      }

      print('All scheduled notifications have been cancelled');
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }

  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
    int notificationId = 0,
  }) async {
    print('=== Scheduling daily notification for $hour:$minute ===');

    if (!_isInitialized) {
      print('Service not initialized, initializing now...');
      await initialize();
    }

    final hasPermissions = await checkAndroidPermissions();
    if (!hasPermissions) {
      print('Permissions not granted, cannot schedule notification');
      return;
    }

    try {
      // Get current date and timezone info
      final now = tz.TZDateTime.now(tz.local);
      print('Current time: ${now.toString()}');

      // Create scheduled time for the specified hour and minute
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      print('Initial scheduled time: ${scheduledTime.toString()}');

      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        print(
            'Time has passed, rescheduling for tomorrow: ${scheduledTime.toString()}');
      }

      // Cancel only the specific notification if it exists
      await _notifications.cancel(notificationId);
      print('Cancelled notification with ID $notificationId if it existed');

      print('Creating notification details...');
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'vocable_channel',
        'Vocable Notifications',
        channelDescription: 'Notifications for vocabulary learning',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        fullScreenIntent: true,
        ongoing: false,
        autoCancel: true,
        styleInformation: const DefaultStyleInformation(true, true),
      );

      print('Scheduling notification for ${scheduledTime.toString()}...');

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_reminder_$notificationId',
      );

      // Verify the notification was scheduled
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      print('Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print(
            'Pending notification: ID=${notification.id}, Title=${notification.title}');
      }

      print('Notification scheduled successfully');
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
    }
    print('=== Notification scheduling completed ===');
  }

  // Exemple d'utilisation pour planifier plusieurs notifications quotidiennes
  Future<void> scheduleDailyNotifications() async {
    // Notification du matin
    await scheduleDailyNotification(
      title: 'Bonjour!',
      body: 'C\'est l\'heure de réviser vos mots du jour!',
      hour: 9,
      minute: 0,
      notificationId: 900,
    );

    // Notification de l'après-midi
    await scheduleDailyNotification(
      title: 'Rappel',
      body: 'N\'oubliez pas de pratiquer vos mots de vocabulaire!',
      hour: 13,
      minute: 0,
      notificationId: 1300,
    );

    // Notification du soir
    await scheduleDailyNotification(
      title: 'Bonsoir!',
      body: 'Dernière session de révision pour aujourd\'hui!',
      hour: 14,
      minute: 0,
      notificationId: 1400,
    );
  }
}
