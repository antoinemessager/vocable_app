import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TooEasySettingsDialog extends StatefulWidget {
  const TooEasySettingsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const TooEasySettingsDialog(),
    );
  }

  @override
  State<TooEasySettingsDialog> createState() => _TooEasySettingsDialogState();
}

class _TooEasySettingsDialogState extends State<TooEasySettingsDialog> {
  bool _showTooEasyDialog = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_too_easy_dialog') ?? false;
    setState(() {
      _showTooEasyDialog = !hideDialog;
    });
  }

  Future<void> _toggleTooEasyDialog(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_too_easy_dialog', !value);
    setState(() {
      _showTooEasyDialog = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Too Easy Confirmation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When enabled, a confirmation dialog will be shown before marking words as too easy.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Show confirmation dialog',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _showTooEasyDialog,
                onChanged: _toggleTooEasyDialog,
                activeColor: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
