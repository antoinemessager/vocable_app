import 'package:flutter/material.dart';
import '../widgets/daily_goal_dialog.dart';
import '../widgets/notification_settings_dialog.dart';
import '../services/preferences_service.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  int _dailyWordGoal = 5;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _preferencesService.initialize();
    final int dailyWordGoal = await _preferencesService.getDailyWordGoal();
    final bool notificationsEnabled =
        await _preferencesService.getNotificationsEnabled();

    setState(() {
      _dailyWordGoal = dailyWordGoal;
      _notificationsEnabled = notificationsEnabled;
    });
  }

  Future<void> _showDailyGoalDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => DailyGoalDialog(
        initialGoal: _dailyWordGoal,
        onGoalChanged: (int newGoal) async {
          await _preferencesService.setDailyWordGoal(newGoal);
          setState(() {
            _dailyWordGoal = newGoal;
          });
        },
      ),
    );
  }

  Future<void> _showNotificationSettings() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => const NotificationSettingsDialog(),
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
            title: const Text('Notifications'),
            subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
            leading: const Icon(Icons.notifications),
            onTap: _showNotificationSettings,
          ),
          ListTile(
            title: const Text('Help Center'),
            leading: const Icon(Icons.help),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
