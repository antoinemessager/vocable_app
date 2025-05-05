import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_pair.dart';
import '../screens/settings/settings_help_center_screen.dart';
import 'too_easy_dialog.dart';

class WordCard extends StatefulWidget {
  final WordPair word;
  final Function(bool) onAnswer;
  final VoidCallback onTooEasy;
  final VoidCallback? onShowTranslation;

  const WordCard({
    super.key,
    required this.word,
    required this.onAnswer,
    required this.onTooEasy,
    this.onShowTranslation,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _isRevealed = false;

  void _toggleReveal() {
    setState(() {
      _isRevealed = true;
    });
  }

  Future<void> _handleTooEasy() async {
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_too_easy_dialog') ?? false;

    if (!hideDialog) {
      final shouldMarkTooEasy = await TooEasyDialog.show(
        context,
        onTooEasy: widget.onTooEasy,
      );
      if (shouldMarkTooEasy != true) {
        return;
      }
    } else {
      widget.onTooEasy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40, // Hauteur fixe pour le Stack
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        right:
                            0, // Augmentation du décalage pour mieux centrer le mot
                        child: Text(
                          widget.word.word_fr,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.grey,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SettingsHelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _toggleReveal();
                        widget.onShowTranslation?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Afficher la traduction'),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  Text(
                    widget.word.word_es,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (widget.word.es_sentence.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '"${widget.word.es_sentence}"',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.word.fr_sentence.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '(${widget.word.fr_sentence})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: FilledButton(
                                  onPressed: () => widget.onAnswer(false),
                                  style: FilledButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: Colors.red[50],
                                    foregroundColor: Colors.red[700],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.close,
                                          size: constraints.maxWidth < 350
                                              ? 16
                                              : 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Incorrect',
                                        style: TextStyle(
                                            fontSize: constraints.maxWidth < 350
                                                ? 11
                                                : 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: FilledButton(
                                  onPressed: () => widget.onAnswer(true),
                                  style: FilledButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: Colors.green[50],
                                    foregroundColor: Colors.green[700],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check,
                                          size: constraints.maxWidth < 350
                                              ? 16
                                              : 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Correct',
                                        style: TextStyle(
                                            fontSize: constraints.maxWidth < 350
                                                ? 11
                                                : 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.word.nb_time_seen == 1)
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: FilledButton(
                                    onPressed: _handleTooEasy,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      backgroundColor: Colors.grey[100],
                                      foregroundColor: Colors.grey[700],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.double_arrow,
                                            size: constraints.maxWidth < 350
                                                ? 16
                                                : 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Déjà connu',
                                          style: TextStyle(
                                              fontSize:
                                                  constraints.maxWidth < 350
                                                      ? 11
                                                      : 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
