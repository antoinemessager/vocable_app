import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _dailyWordGoalKey = 'daily_word_goal';
  static const int _defaultDailyWordGoal = 10;

  static final PreferencesService instance = PreferencesService._();
  SharedPreferences? _prefs;

  PreferencesService._();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setDailyWordGoal(int goal) async {
    await _prefs?.setInt(_dailyWordGoalKey, goal);
  }

  int getDailyWordGoal() {
    return _prefs?.getInt(_dailyWordGoalKey) ?? _defaultDailyWordGoal;
  }
}
