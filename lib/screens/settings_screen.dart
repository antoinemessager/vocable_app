import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int dailyWordGoal = 10;

  Widget _buildSettingItem(String title, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      children: [
        // Daily Learning Goal
        Text(
          'Daily Learning Goal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            // TODO: Implement goal adjustment
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$dailyWordGoal words per day',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Other Settings
        _buildSettingItem(
          'Notifications',
          Icons.notifications_outlined,
          onTap: () {
            // TODO: Implement notifications settings
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
