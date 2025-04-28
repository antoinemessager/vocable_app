import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _dailyWordGoalKey = 'daily_word_goal';
  static const String _startingLevelKey = 'starting_level';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';
  static const String _hasShownHelpKey = 'has_shown_help';

  Future<int> getDailyWordGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyWordGoalKey) ?? 5;
  }

  Future<void> setDailyWordGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyWordGoalKey, goal);
  }

  Future<String> getStartingLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_startingLevelKey) ?? 'A1';
  }

  Future<void> setStartingLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startingLevelKey, level);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_notificationHourKey) ?? 9;
    final minute = prefs.getInt(_notificationMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationHourKey, time.hour);
    await prefs.setInt(_notificationMinuteKey, time.minute);
  }

  Future<DateTime?> getLastStreakAnimationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('last_streak_animation_date');
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  Future<void> setLastStreakAnimationDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_streak_animation_date', date.toIso8601String());
  }

  Future<double> getPreviousProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('previous_progress') ?? 0.0;
  }

  Future<void> setPreviousProgress(double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('previous_progress', progress);
  }

  Future<bool> getHasShownHelp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasShownHelpKey) ?? false;
  }

  Future<void> setHasShownHelp(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasShownHelpKey, value);
  }
}
