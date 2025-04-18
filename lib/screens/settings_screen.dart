import 'package:flutter/material.dart';
import '../widgets/daily_goal_dialog.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int dailyWordGoal;

  @override
  void initState() {
    super.initState();
    dailyWordGoal = PreferencesService.instance.getDailyWordGoal();
  }

  Future<void> _showDailyGoalDialog() async {
    await showDialog(
      context: context,
      builder: (context) => DailyGoalDialog(
        initialGoal: dailyWordGoal,
        onGoalChanged: (newGoal) async {
          await PreferencesService.instance.setDailyWordGoal(newGoal);
          setState(() => dailyWordGoal = newGoal);
        },
      ),
    );
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
    return ListView(
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        _buildSettingItem(
          'Daily Learning Goal',
          Icons.flag_outlined,
          subtitle: '$dailyWordGoal words per day',
          onTap: _showDailyGoalDialog,
        ),
        _buildSettingItem(
          'Notifications',
          Icons.notifications_outlined,
          onTap: () {
            // TODO: Implement notifications settings
          },
        ),
        _buildSettingItem(
          'Edit Profile',
          Icons.person_outline,
          onTap: () {
            // TODO: Implement profile editing
          },
        ),
        _buildSettingItem(
          'Help Center',
          Icons.help_outline,
          onTap: () {
            // TODO: Implement help center
          },
        ),
      ],
    );
  }
}
