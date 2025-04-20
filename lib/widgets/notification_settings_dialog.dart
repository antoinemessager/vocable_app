import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/background_service.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  bool _enableNotifications = false;
  final BackgroundService _backgroundService = BackgroundService();

  @override
  void initState() {
    super.initState();
    print('NotificationSettingsDialog: initState called');
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    print('NotificationSettingsDialog: Loading preferences...');
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    print('NotificationSettingsDialog: Current notification state: $enabled');
    setState(() {
      _enableNotifications = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    print('NotificationSettingsDialog: Toggling notifications to: $value');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    print('NotificationSettingsDialog: Preferences updated');

    setState(() {
      _enableNotifications = value;
    });

    if (value) {
      print('NotificationSettingsDialog: Starting background service...');
      await _backgroundService.startService();
      print('NotificationSettingsDialog: Background service started');
    } else {
      print('NotificationSettingsDialog: Stopping background service...');
      await _backgroundService.stopService();
      print('NotificationSettingsDialog: Background service stopped');
      print('NotificationSettingsDialog: Clearing all notifications...');
      await _backgroundService.clearAllNotifications();
      print('NotificationSettingsDialog: All notifications cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _enableNotifications,
            onChanged: _toggleNotifications,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            print('NotificationSettingsDialog: Dialog closed');
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
