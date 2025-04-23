import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/preferences_service.dart';
import '../../widgets/too_easy_settings_dialog.dart';
import 'settings_help_center_screen.dart';
import 'settings_daily_goal_screen.dart';
import 'settings_notification_time_screen.dart';
import 'settings_assessment_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  int _dailyWordGoal = 5;
  bool _notificationsEnabled = false;
  bool _showTooEasyDialog = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    //await _preferencesService.initialize();
    final int dailyWordGoal = await _preferencesService.getDailyWordGoal();
    final bool notificationsEnabled =
        await _preferencesService.getNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_too_easy_dialog') ?? false;

    setState(() {
      _dailyWordGoal = dailyWordGoal;
      _notificationsEnabled = notificationsEnabled;
      _showTooEasyDialog = !hideDialog;
    });
  }

  Future<void> _showDailyGoalDialog() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => const DailyGoalScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _dailyWordGoal = result;
      });
    }
  }

  Future<void> _showNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationTimeScreen(),
      ),
    );
    await _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 60,
          bottom: 16,
        ),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                    ),
                    Text(
                      'Customize your experience',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Daily Word Goal'),
            subtitle: Text('$_dailyWordGoal words per day'),
            leading: const Icon(Icons.flag),
            onTap: _showDailyGoalDialog,
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: _showNotificationSettings,
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Take Level Assessment'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsAssessmentScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Help Center'),
            leading: const Icon(Icons.help),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsHelpCenterScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Too Easy Confirmation'),
            subtitle: Text(_showTooEasyDialog ? 'Enabled' : 'Disabled'),
            leading: const Icon(Icons.warning_amber_rounded),
            onTap: () => TooEasySettingsDialog.show(context)
                .then((_) => _loadPreferences()),
          ),
        ],
      ),
    );
  }
}
