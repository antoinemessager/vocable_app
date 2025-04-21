import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  bool _notificationsEnabled = false;
  final _prefs = SharedPreferences.getInstance();
  final _notificationService = NotificationService();
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadPendingNotifications();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _loadPendingNotifications() async {
    final notifications = await _notificationService.getPendingNotifications();
    setState(() {
      _pendingNotifications = notifications;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _notificationService.sendTestNotification();
      // Si les notifications sont activées, on programme une notification de test dans 10 secondes
      await _notificationService.scheduleNotificationIn10Seconds();
      // Et on programme aussi la notification quotidienne
      await _notificationService.scheduleDailyNotifications();
    } else {
      // Si les notifications sont désactivées, on annule toutes les notifications
      await _notificationService.cancelAllNotifications();
    }
    await _loadPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paramètres des notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Activer les notifications'),
            subtitle:
                const Text('Recevez une notification quotidienne à 10:31'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const SizedBox(height: 16),
          if (_pendingNotifications.isNotEmpty) ...[
            const Text('Notifications en attente :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._pendingNotifications.map((notification) => ListTile(
                  title: Text(notification.title ?? 'Sans titre'),
                  subtitle: Text(notification.body ?? 'Sans contenu'),
                  trailing: Text('ID: ${notification.id}'),
                )),
          ] else
            const Text('Aucune notification en attente'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
