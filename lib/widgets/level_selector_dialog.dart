import 'package:flutter/material.dart';
import '../services/database_service.dart';

class LevelSelectorDialog extends StatelessWidget {
  final Map<String, dynamic> word;
  final VoidCallback onLevelChanged;

  const LevelSelectorDialog({
    super.key,
    required this.word,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      {'level': 0, 'text': 'Inconnu'},
      {'level': 1, 'text': 'Niveau 1'},
      {'level': 2, 'text': 'Niveau 2'},
      {'level': 3, 'text': 'Niveau 3'},
      {'level': 4, 'text': 'Niveau 4'},
      {'level': 5, 'text': 'Connu'},
    ];
    final currentLevel = word['box_level'] as int;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word['french_word'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            word['spanish_word'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            final isSelected = level['level'] == currentLevel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () async {
                  final wordId = word['word_id'] as int;
                  await DatabaseService.instance
                      .updateWordLevel(wordId, level['level'] as int);
                  onLevelChanged();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    level['text'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    );
  }
}
