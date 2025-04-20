import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import 'package:flutter/material.dart';
import 'background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final BackgroundService _backgroundService = BackgroundService();
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

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

    await _notifications.initialize(initializationSettings);
    await _backgroundService.initialize();
    _isInitialized = true;

    // Configure le canal de notification Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vocable_channel',
      'Vocable Notifications',
      description: 'Notifications for vocabulary learning',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    await initialize();

    // Annule toutes les notifications existantes
    await cancelAllNotifications();

    // Enregistre l'heure de notification dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_time', '${time.hour}:${time.minute}');

    // Programme une notification de test immédiate
    const AndroidNotificationDetails androidNotificationDetails =
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
      ongoing: true,
      autoCancel: false,
      styleInformation: DefaultStyleInformation(true, true),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
