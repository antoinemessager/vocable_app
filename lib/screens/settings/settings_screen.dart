import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/preferences_service.dart';
import '../../widgets/too_easy_settings_dialog.dart';
import 'settings_help_center_screen.dart';
import 'settings_daily_goal_screen.dart';
import 'settings_notification_time_screen.dart';
import 'settings_assessment_screen.dart';
import 'settings_verb_tenses_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final bool notificationsEnabled =
        await _preferencesService.getNotificationsEnabled();

    setState(() {
      _notificationsEnabled = notificationsEnabled;
    });
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
          top: 40,
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
                      'Paramètres',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                    ),
                    Text(
                      'Personnalise ton expérience',
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
          FutureBuilder<Map<String, int>>(
            future: SharedPreferences.getInstance().then((prefs) => {
                  'wordsPerDay': prefs.getInt('daily_word_goal') ?? 5,
                  'verbsPerDay': prefs.getInt('daily_verb_goal') ?? 2,
                }),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  title: Text('Définis tes objectifs'),
                  subtitle: Text('Chargement...'),
                  leading: Icon(Icons.flag),
                  onTap: null,
                );
              }
              return ListTile(
                title: const Text('Définis tes objectifs'),
                subtitle: Text(
                    '${snapshot.data!['wordsPerDay']} mots et ${snapshot.data!['verbsPerDay']} verbes par jour',
                    style: const TextStyle(color: Colors.black45)),
                leading: const Icon(Icons.flag),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsDailyGoalScreen(),
                    ),
                  );
                  if (result != null) {
                    setState(() {});
                  }
                },
              );
            },
          ),
          ListTile(
            title: const Text('Temps verbaux',
                style: TextStyle(color: Colors.black87)),
            subtitle: const Text('Sélectionne les temps à apprendre',
                style: TextStyle(color: Colors.black45)),
            leading: const Icon(Icons.access_time, color: Colors.black87),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsVerbTensesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.black87),
            title: const Text('Notifications',
                style: TextStyle(color: Colors.black87)),
            onTap: _showNotificationSettings,
            subtitle: Text(_notificationsEnabled ? 'Activées' : 'Désactivées',
                style: const TextStyle(color: Colors.black45)),
          ),
          ListTile(
            leading: const Icon(Icons.quiz, color: Colors.black87),
            title: const Text('Repasser l\'évaluation',
                style: TextStyle(color: Colors.black87)),
            subtitle: FutureBuilder<String>(
              future: PreferencesService().getStartingLevel(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Chargement...',
                      style: TextStyle(color: Colors.black45));
                }
                return Text(
                  'Niveau actuel : ${snapshot.data}',
                  style: const TextStyle(color: Colors.black45),
                );
              },
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsAssessmentScreen(),
                ),
              );
              setState(() {});
            },
          ),
          ListTile(
            title: const Text('Centre d\'aide',
                style: TextStyle(color: Colors.black87)),
            leading: const Icon(Icons.help, color: Colors.black87),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsHelpCenterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
