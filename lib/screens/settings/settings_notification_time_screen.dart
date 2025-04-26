import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../widgets/clock_painter.dart';

class NotificationTimeScreen extends StatefulWidget {
  const NotificationTimeScreen({super.key});

  @override
  State<NotificationTimeScreen> createState() => _NotificationTimeScreenState();
}

class _NotificationTimeScreenState extends State<NotificationTimeScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _prefs = SharedPreferences.getInstance();
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _programNotification(int hour, int minute) async {
    // D'abord annuler toute notification existante
    await _notificationService.cancelAllNotifications();

    // Puis programmer la nouvelle notification
    await _notificationService.scheduleDailyNotification(
      title: 'Rappel Vocable',
      body: 'C\'est l\'heure de pratiquer votre vocabulaire !',
      hour: hour,
      minute: minute,
      notificationId: 1000,
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _programNotification(_selectedTime.hour, _selectedTime.minute);
    } else {
      await _notificationService.cancelAllNotifications();
    }
  }

  Future<void> _updateTime(TimeOfDay time) async {
    final prefs = await _prefs;
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);
    setState(() {
      _selectedTime = time;
    });

    // Si les notifications sont activées, reprogrammer avec la nouvelle heure
    if (_notificationsEnabled) {
      await _programNotification(time.hour, time.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Rappels Quotidiens',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue[100],
                  inactiveTrackColor: Colors.grey[300],
                  inactiveThumbColor: Colors.grey[400],
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ),
            if (_notificationsEnabled) ...[
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heure du Rappel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.blue,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  timePickerTheme: TimePickerThemeData(
                                    backgroundColor: Colors.white,
                                    hourMinuteColor:
                                        Colors.blue.withOpacity(0.1),
                                    hourMinuteTextColor: Colors.black,
                                    dayPeriodColor:
                                        Colors.blue.withOpacity(0.1),
                                    dayPeriodTextColor: Colors.black,
                                    dialHandColor: Colors.blue,
                                    dialBackgroundColor:
                                        Colors.blue.withOpacity(0.1),
                                    dialTextColor: Colors.black,
                                    entryModeIconColor: Colors.blue,
                                  ),
                                ),
                                child: MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (picked != null) {
                            await _updateTime(picked);
                          }
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: ClockPainter(
                                  time: _selectedTime,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.period == DayPeriod.am
                                      ? 'AM'
                                      : 'PM',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Vous recevrez une notification quotidienne à cette heure pour vous rappeler de pratiquer votre vocabulaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
