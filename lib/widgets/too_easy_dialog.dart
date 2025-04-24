import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TooEasyDialog extends StatelessWidget {
  const TooEasyDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => const TooEasyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 20, 12),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Es-tu sûr?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Si tu marques ce mot comme "déjà connu", il ne comptera pas dans ta progression et tu ne le verras plus dans tes révisions.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<bool>(
                future: SharedPreferences.getInstance().then(
                    (prefs) => prefs.getBool('hide_too_easy_dialog') ?? false),
                builder: (context, snapshot) {
                  final hideDialog = snapshot.data ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: hideDialog,
                          onChanged: (value) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                                'hide_too_easy_dialog', value ?? false);
                            setState(() {});
                          },
                          activeColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ne plus afficher ce message',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      actions: [
        Row(
          //mainAxisAlignment: MainAxisAlignment.left,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
