import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

@pragma('vm:entry-point')
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static Timer? _notificationTimer;
  static int _notificationCounter = 0;
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static bool _isServiceRunning = false;

  factory BackgroundService() {
    return _instance;
  }

  BackgroundService._internal();

  Future<void> initialize() async {
    print('BackgroundService: Initializing...');

    // Initialisation des notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vocable_channel',
      'Vocable Notifications',
      description: 'Notifications for vocabulary learning',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print('BackgroundService: Notification channel created');

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'vocable_channel',
        initialNotificationTitle: 'Vocable',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    print('BackgroundService: Service configured');
  }

  Future<void> startService() async {
    if (_isServiceRunning) {
      print(
          'BackgroundService: Service is already running, stopping it first...');
      await stopService();
    }
    print('BackgroundService: Starting service...');
    await _service.startService();
    _isServiceRunning = true;
    print('BackgroundService: Service started successfully');
  }

  Future<void> stopService() async {
    print('BackgroundService: Stopping service...');
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _isServiceRunning = false;
    try {
      _service.invoke('stopService');
    } catch (e) {
      print('BackgroundService: Error stopping service: $e');
    }
    print('BackgroundService: Service stopped successfully');
  }

  Future<void> clearAllNotifications() async {
    print('BackgroundService: Clearing all notifications...');
    await _notifications.cancelAll();
    print('BackgroundService: All notifications cleared successfully');
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    print('BackgroundService: onStart called');
    _isServiceRunning = true;

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        print('BackgroundService: Setting as foreground');
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        print('BackgroundService: Setting as background');
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      print('BackgroundService: Received stopService event');
      _notificationTimer?.cancel();
      _notificationTimer = null;
      _isServiceRunning = false;
      service.stopSelf();
      print('BackgroundService: Service stopped by stopService event');
    });

    // Vérifie toutes les 10 secondes si les notifications sont activées
    _notificationTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      print('BackgroundService: Checking for notifications...');
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;

      print('BackgroundService: Notifications enabled: $notificationsEnabled');

      if (notificationsEnabled) {
        await _sendNotification();
      } else {
        print(
            'BackgroundService: Notifications are disabled, stopping service...');
        await _notifications.cancelAll();
        timer.cancel();
        _notificationTimer = null;
        _isServiceRunning = false;
        service.stopSelf();
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> _sendNotification() async {
    print('BackgroundService: Preparing to send notification...');

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'vocable_channel',
      'Vocable Notifications',
      channelDescription: 'Notifications for vocabulary learning',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      autoCancel: true,
      ongoing: false,
      onlyAlertOnce: false,
      fullScreenIntent: true,
      styleInformation: DefaultStyleInformation(true, true),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Utiliser un ID unique pour chaque notification
    final notificationId = _notificationCounter++;

    // Supprimer la notification précédente si elle existe
    if (notificationId > 0) {
      print('BackgroundService: Cancelling previous notification');
      await _notifications.cancel(notificationId - 1);
    }

    await _notifications.show(
      notificationId,
      'Time to learn!',
      'Don\'t forget to practice your vocabulary today!',
      notificationDetails,
    );

    print(
        'BackgroundService: Notification sent successfully with ID: $notificationId');
  }
}
