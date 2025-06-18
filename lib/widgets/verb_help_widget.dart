import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../screens/settings/settings_help_center_screen.dart';

class VerbHelpWidget {
  static final PreferencesService _preferencesService = PreferencesService();

  static void showFirstCardHelp(BuildContext context, bool hasShownHelp,
      {VoidCallback? onFirstPopupShown}) {
    if (!hasShownHelp) {
      onFirstPopupShown?.call();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Fonctionnement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lis le verbe, pense à sa conjugaison au temps indiqué et appuie sur afficher la conjugaison.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  static void showAnswerHelp(
      BuildContext context, bool hasShownHelp, bool hasShownFirstPopup) {
    if (!hasShownHelp && hasShownFirstPopup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Où cliquer?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(
                      icon: Icons.double_arrow,
                      color: Colors.grey[700]!,
                      title: 'Déjà vu',
                      description:
                          'Tu connaissais déjà parfaitement la conjugaison et tu ne veux plus jamais la revoir ?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.check,
                      color: Colors.green[700]!,
                      title: 'Correct',
                      description:
                          'Tu as eu juste et tu veux continuer à réviser ce verbe ?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.close,
                      color: Colors.red[700]!,
                      title: 'Incorrect',
                      description: 'Tu t\'es trompé ?',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: hasShownHelp,
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() {
                                // Note: This will only update the local state in the dialog
                                // The actual state should be updated in the parent widget
                              });
                              await _preferencesService.setHasShownHelp(value);
                            }
                          },
                        ),
                        const Text('Ne plus voir'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsHelpCenterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('En savoir plus'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  static Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
