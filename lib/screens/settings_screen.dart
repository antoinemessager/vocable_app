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
        await _preferencesService.getEnableNotifications();

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

  Widget _buildSettingItem(String title, IconData icon,
      {required VoidCallback onTap, String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Daily Word Goal'),
            subtitle: Text('$_dailyWordGoal words per day'),
            leading: const Icon(Icons.flag),
            onTap: _showDailyGoalDialog,
          ),
          ListTile(
            title: const Text('Notification Settings'),
            subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
            leading: const Icon(Icons.notifications),
            onTap: _showNotificationSettings,
          ),
          ListTile(
            title: const Text('Help Center'),
            leading: const Icon(Icons.help),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
        ],
      ),
    );
  }
}
