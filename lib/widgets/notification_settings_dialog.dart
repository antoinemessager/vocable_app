import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  final NotificationService _notificationService = NotificationService();
  final PreferencesService _preferencesService = PreferencesService();
  bool _notificationsEnabled = false;
  bool _showBadge = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _preferencesService.initialize();
    final bool notificationsEnabled =
        await _preferencesService.getEnableNotifications();
    final bool showBadge = await _preferencesService.getShowBadge();
    final TimeOfDay notificationTime =
        await _preferencesService.getNotificationTime();

    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _showBadge = showBadge;
      _notificationTime = notificationTime;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _preferencesService.setEnableNotifications(value);

    if (value) {
      final bool granted = await _notificationService.requestPermission();
      if (!granted) {
        setState(() {
          _notificationsEnabled = false;
        });
        await _preferencesService.setEnableNotifications(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permissions are required'),
            ),
          );
        }
      }
    } else {
      await _notificationService.cancelNotification(1);
    }
  }

  Future<void> _updateNotificationSettings() async {
    await _preferencesService.setEnableNotifications(_notificationsEnabled);
    await _preferencesService.setShowBadge(_showBadge);
    await _preferencesService.setNotificationTime(_notificationTime);

    if (_notificationsEnabled) {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _notificationTime.hour,
        _notificationTime.minute,
      );

      if (scheduledTime.isAfter(now)) {
        await _notificationService.scheduleNotification(
          id: 1,
          title: 'Time to Learn!',
          body: 'Don\'t forget to learn your daily words',
          scheduledDate: scheduledTime,
        );
      }
    } else {
      await _notificationService.cancelNotification(1);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: const Text('Show Badge'),
              value: _showBadge,
              onChanged: (bool value) {
                setState(() {
                  _showBadge = value;
                });
              },
            ),
            ListTile(
              title: const Text('Notification Time'),
              subtitle: Text(_notificationTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _updateNotificationSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
