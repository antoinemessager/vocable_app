import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _wordsPerDayKey = 'words_per_day';
  static const String _startingLevelKey = 'starting_level';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';
  static const String _hasShownHelpKey = 'has_shown_help';
  static const String _verbsPerDayKey = 'verbs_per_day';
  static const String _previousWordProgressKey = 'previous_word_progress';
  static const String _previousVerbProgressKey = 'previous_verb_progress';

  // Cache pour les valeurs fréquemment utilisées
  static SharedPreferences? _prefs;
  static int? _cachedWordsPerDay;
  static double? _cachedPreviousWordProgress;
  static double? _cachedPreviousVerbProgress;
  static bool? _cachedHasShownHelp;
  static int? _cachedVerbsPerDay;

  // Initialisation du cache
  static Future<void> _initCache() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _cachedWordsPerDay = _prefs!.getInt(_wordsPerDayKey);
      _cachedPreviousWordProgress = _prefs!.getDouble(_previousWordProgressKey);
      _cachedPreviousVerbProgress = _prefs!.getDouble(_previousVerbProgressKey);
      _cachedHasShownHelp = _prefs!.getBool(_hasShownHelpKey);
      _cachedVerbsPerDay = _prefs!.getInt(_verbsPerDayKey);
    }
  }

  Future<int> getWordsPerDay() async {
    await _initCache();
    _cachedWordsPerDay ??= _prefs!.getInt(_wordsPerDayKey) ?? 10;
    return _cachedWordsPerDay!;
  }

  Future<void> setWordsPerDay(int value) async {
    await _initCache();
    await _prefs!.setInt(_wordsPerDayKey, value);
    _cachedWordsPerDay = value;
  }

  Future<int> getVerbsPerDay() async {
    await _initCache();
    _cachedVerbsPerDay ??= _prefs!.getInt(_verbsPerDayKey) ?? 2;
    return _cachedVerbsPerDay!;
  }

  Future<void> setVerbsPerDay(int value) async {
    await _initCache();
    await _prefs!.setInt(_verbsPerDayKey, value);
    _cachedVerbsPerDay = value;
  }

  Future<String> getStartingLevel() async {
    await _initCache();
    return _prefs!.getString(_startingLevelKey) ?? 'A1';
  }

  Future<void> setStartingLevel(String level) async {
    await _initCache();
    await _prefs!.setString(_startingLevelKey, level);
  }

  Future<bool> getNotificationsEnabled() async {
    await _initCache();
    return _prefs!.getBool(_notificationsEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _initCache();
    await _prefs!.setBool(_notificationsEnabledKey, enabled);
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

  Future<double> getPreviousWordProgress() async {
    await _initCache();
    _cachedPreviousWordProgress ??=
        _prefs!.getDouble(_previousWordProgressKey) ?? 0.0;
    return _cachedPreviousWordProgress!;
  }

  Future<void> setPreviousWordProgress(double progress) async {
    await _initCache();
    await _prefs!.setDouble(_previousWordProgressKey, progress);
    _cachedPreviousWordProgress = progress;
  }

  Future<double> getPreviousVerbProgress() async {
    await _initCache();
    _cachedPreviousVerbProgress ??=
        _prefs!.getDouble(_previousVerbProgressKey) ?? 0.0;
    return _cachedPreviousVerbProgress!;
  }

  Future<void> setPreviousVerbProgress(double progress) async {
    await _initCache();
    await _prefs!.setDouble(_previousVerbProgressKey, progress);
    _cachedPreviousVerbProgress = progress;
  }

  Future<bool> getHasShownHelp() async {
    await _initCache();
    _cachedHasShownHelp ??= _prefs!.getBool(_hasShownHelpKey) ?? false;
    return _cachedHasShownHelp!;
  }

  Future<void> setHasShownHelp(bool value) async {
    await _initCache();
    await _prefs!.setBool(_hasShownHelpKey, value);
    _cachedHasShownHelp = value;
  }

  Future<List<String>> getSelectedVerbTenses() async {
    await _initCache();
    return _prefs!.getStringList('selected_verb_tenses') ?? ['présent'];
  }

  Future<void> setSelectedVerbTenses(List<String> tenses) async {
    await _initCache();
    await _prefs!.setStringList('selected_verb_tenses', tenses);
  }

  Future<void> initializeVerbTenses() async {
    await _initCache();
    final currentTenses = _prefs!.getStringList('selected_verb_tenses');
    if (currentTenses == null || currentTenses.isEmpty) {
      await _prefs!.setStringList('selected_verb_tenses', ['présent']);
    }
  }
}
