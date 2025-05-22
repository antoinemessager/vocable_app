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

  // Cache pour les valeurs fréquemment utilisées
  static SharedPreferences? _prefs;
  static int? _cachedDailyWordGoal;
  static double? _cachedPreviousProgress;
  static bool? _cachedHasShownHelp;

  // Initialisation du cache
  static Future<void> _initCache() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _cachedDailyWordGoal = _prefs!.getInt(_dailyWordGoalKey);
      _cachedPreviousProgress = _prefs!.getDouble('previous_progress');
      _cachedHasShownHelp = _prefs!.getBool(_hasShownHelpKey);
    }
  }

  Future<int> getDailyWordGoal() async {
    await _initCache();
    if (_cachedDailyWordGoal == null) {
      _cachedDailyWordGoal = _prefs!.getInt(_dailyWordGoalKey) ?? 5;
    }
    return _cachedDailyWordGoal!;
  }

  Future<void> setDailyWordGoal(int value) async {
    await _initCache();
    await _prefs!.setInt(_dailyWordGoalKey, value);
    _cachedDailyWordGoal = value;
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
    await _initCache();
    final hour = _prefs!.getInt(_notificationHourKey) ?? 20;
    final minute = _prefs!.getInt(_notificationMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    await _initCache();
    await _prefs!.setInt(_notificationHourKey, time.hour);
    await _prefs!.setInt(_notificationMinuteKey, time.minute);
  }

  Future<DateTime?> getLastStreakAnimationDate() async {
    await _initCache();
    final dateString = _prefs!.getString('last_streak_animation_date');
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  Future<void> setLastStreakAnimationDate(DateTime date) async {
    await _initCache();
    await _prefs!
        .setString('last_streak_animation_date', date.toIso8601String());
  }

  Future<double> getPreviousProgress() async {
    await _initCache();
    if (_cachedPreviousProgress == null) {
      _cachedPreviousProgress = _prefs!.getDouble('previous_progress') ?? 0.0;
    }
    return _cachedPreviousProgress!;
  }

  Future<void> setPreviousProgress(double progress) async {
    await _initCache();
    await _prefs!.setDouble('previous_progress', progress);
    _cachedPreviousProgress = progress;
  }

  Future<bool> getHasShownHelp() async {
    await _initCache();
    if (_cachedHasShownHelp == null) {
      _cachedHasShownHelp = _prefs!.getBool(_hasShownHelpKey) ?? false;
    }
    return _cachedHasShownHelp!;
  }

  Future<void> setHasShownHelp(bool value) async {
    await _initCache();
    await _prefs!.setBool(_hasShownHelpKey, value);
    _cachedHasShownHelp = value;
  }

  Future<void> initializeVerbTenses() async {
    await _initCache();
    await _prefs!.setStringList('selected_verb_tenses', ['présent']);
  }
}
