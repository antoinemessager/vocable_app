import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;
  bool _initialized = false;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  static const String _dailyWordGoalKey = 'daily_word_goal';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';

  Future<int> getDailyWordGoal() async {
    await initialize();
    return _prefs.getInt(_dailyWordGoalKey) ?? 5;
  }

  Future<void> setDailyWordGoal(int goal) async {
    await initialize();
    await _prefs.setInt(_dailyWordGoalKey, goal);
  }

  Future<bool> getNotificationsEnabled() async {
    await initialize();
    return _prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await initialize();
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<TimeOfDay?> getNotificationTime() async {
    await initialize();
    final timeString = _prefs.getString(_notificationTimeKey);
    if (timeString == null) return null;
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    await initialize();
    final timeString = '${time.hour}:${time.minute}';
    await _prefs.setString(_notificationTimeKey, timeString);
  }
}
