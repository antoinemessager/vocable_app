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
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _showBadgeKey = 'show_badge';
  static const String _showLockScreenKey = 'show_lock_screen';
  static const String _notificationTimeHourKey = 'notification_time_hour';
  static const String _notificationTimeMinuteKey = 'notification_time_minute';

  Future<int> getDailyWordGoal() async {
    return _prefs.getInt(_dailyWordGoalKey) ?? 5;
  }

  Future<void> setDailyWordGoal(int goal) async {
    await _prefs.setInt(_dailyWordGoalKey, goal);
  }

  Future<bool> getEnableNotifications() async {
    return _prefs.getBool(_enableNotificationsKey) ?? false;
  }

  Future<void> setEnableNotifications(bool value) async {
    await _prefs.setBool(_enableNotificationsKey, value);
  }

  Future<bool> getShowBadge() async {
    return _prefs.getBool(_showBadgeKey) ?? true;
  }

  Future<void> setShowBadge(bool value) async {
    await _prefs.setBool(_showBadgeKey, value);
  }

  Future<bool> getShowLockScreen() async {
    return _prefs.getBool(_showLockScreenKey) ?? true;
  }

  Future<void> setShowLockScreen(bool value) async {
    await _prefs.setBool(_showLockScreenKey, value);
  }

  Future<TimeOfDay> getNotificationTime() async {
    final String? timeStr = _prefs.getString('notificationTime');
    if (timeStr == null) {
      return const TimeOfDay(hour: 9, minute: 0); // Default to 9:00 AM
    }

    final List<String> parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    await _prefs.setString('notificationTime', '${time.hour}:${time.minute}');
  }
}
