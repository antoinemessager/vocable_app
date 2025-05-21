import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'too_easy_dialog.dart';
import '../services/database_service.dart';

class VerbCard extends StatefulWidget {
  final String verb;
  final String tense;
  final String conjugation;
  final int verb_id;
  final int nbTimeSeen;
  final VoidCallback? onShowConjugation;
  final Function(bool)? onCorrect;
  final Function(bool)? onIncorrect;
  final Function(bool)? onAlreadyKnown;

  const VerbCard({
    super.key,
    required this.verb,
    required this.tense,
    required this.conjugation,
    required this.verb_id,
    required this.nbTimeSeen,
    this.onShowConjugation,
    this.onCorrect,
    this.onIncorrect,
    this.onAlreadyKnown,
  });

  @override
  State<VerbCard> createState() => _VerbCardState();
}

class _VerbCardState extends State<VerbCard> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(VerbCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verb != widget.verb || oldWidget.tense != widget.tense) {
      setState(() {
        _isRevealed = false;
      });
    }
  }

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
        onTooEasy: () async {
          await DatabaseService.instance
              .recordVerbProgress(widget.verb_id, isTooEasy: true);
          widget.onAlreadyKnown?.call(true);
        },
      );
      if (shouldMarkTooEasy != true) {
        return;
      }
    } else {
      await DatabaseService.instance
          .recordVerbProgress(widget.verb_id, isTooEasy: true);
      widget.onAlreadyKnown?.call(true);
    }
  }

  List<TextSpan> _parseConjugation(String text) {
    final List<TextSpan> spans = [];
    final RegExp starPattern = RegExp(r'\*([^*]+)\*');
    int lastIndex = 0;

    // Vérifier si c'est un temps avec auxiliaire en comptant les mots
    final bool hasAuxiliary = text.trim().split(' ').length > 1;

    if (hasAuxiliary) {
      // Séparer l'auxiliaire et le participe passé
      final parts = text.split(' ');
      if (parts.length >= 2) {
        // Traiter l'auxiliaire
        final auxiliary = parts[0];
        spans.add(TextSpan(
          text: auxiliary,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.normal,
          ),
        ));
        spans.add(const TextSpan(text: '\n')); // Retour à la ligne

        // Traiter le participe passé
        final participle = parts.sublist(1).join(' ');
        for (final match in starPattern.allMatches(participle)) {
          // Ajouter le texte avant l'étoile
          if (match.start > lastIndex) {
            spans.add(TextSpan(
              text: participle.substring(lastIndex, match.start),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ));
          }

          // Ajouter le texte entre les étoiles en gras et bleu
          spans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ));

          lastIndex = match.end;
        }

        // Ajouter le reste du texte
        if (lastIndex < participle.length) {
          spans.add(TextSpan(
            text: participle.substring(lastIndex),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ));
        }
      }
    } else {
      // Traitement normal pour les temps sans auxiliaire
      for (final match in starPattern.allMatches(text)) {
        // Ajouter le texte avant l'étoile
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ));
        }

        // Ajouter le texte entre les étoiles en gras et bleu
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ));

        lastIndex = match.end;
      }

      // Ajouter le reste du texte
      if (lastIndex < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.normal,
          ),
        ));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        child: Text(
                          widget.verb,
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
                            // TODO: Show help dialog
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.tense,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (!_isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _toggleReveal();
                        widget.onShowConjugation?.call();
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
                      child: const Text('Afficher la conjugaison'),
                    ),
                  ),
                ] else ...[
                  _buildConjugationTable(),
                  const SizedBox(height: 16),
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
                                  onPressed: () async {
                                    await DatabaseService.instance
                                        .recordVerbProgress(widget.verb_id,
                                            isCorrect: false);
                                    widget.onIncorrect?.call(false);
                                  },
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
                                                ? 9
                                                : 11),
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
                                  onPressed: () async {
                                    await DatabaseService.instance
                                        .recordVerbProgress(widget.verb_id,
                                            isCorrect: true);
                                    widget.onCorrect?.call(true);
                                  },
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
                                                ? 9
                                                : 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.nbTimeSeen == 1)
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
                                                      ? 9
                                                      : 11),
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

  Widget _buildConjugationTable() {
    print('Raw conjugation: ${widget.conjugation}'); // Debug raw input

    // Séparer sur les virgules et nettoyer le texte
    final conjugations =
        widget.conjugation.split(',').map((line) => line.trim()).toList();

    print('Number of conjugations: ${conjugations.length}'); // Debug count
    print('Conjugations: $conjugations'); // Debug content

    // Vérifier que nous avons 5 ou 6 lignes de conjugaison
    if (conjugations.length != 6 && conjugations.length != 5) {
      return const Center(
        child: Text(
          'Format de conjugaison invalide',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (conjugations.length == 5) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '-',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _parseConjugation(conjugations[0]),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _parseConjugation(conjugations[1]),
                          ),
                        ),
                      ),
                    ] else ...[
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: _parseConjugation(conjugations[i]),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = (conjugations.length == 5 ? 2 : 3);
                        i < conjugations.length;
                        i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _parseConjugation(conjugations[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
