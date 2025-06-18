import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'too_easy_dialog.dart';
import '../services/database_service.dart';
import '../models/verb.dart';

class VerbCard extends StatefulWidget {
  final Verb verb;
  final VoidCallback? onShowConjugation;
  final Function(bool)? onCorrect;
  final Function(bool)? onIncorrect;
  final Function(bool)? onAlreadyKnown;
  final VoidCallback? onShowHelp;

  const VerbCard({
    super.key,
    required this.verb,
    this.onShowConjugation,
    this.onCorrect,
    this.onIncorrect,
    this.onAlreadyKnown,
    this.onShowHelp,
  });

  @override
  State<VerbCard> createState() => _VerbCardState();
}

class _VerbCardState extends State<VerbCard> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(VerbCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.verb.verbes != widget.verb.verbes ||
        oldWidget.verb.temps != widget.verb.temps) {
      setState(() {
        _isRevealed = false;
      });
    }
  }

  void _toggleReveal() {
    setState(() {
      _isRevealed = true;
    });
    widget.onShowHelp?.call();
  }

  Future<void> _handleTooEasy() async {
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_too_easy_dialog') ?? false;

    if (!hideDialog) {
      final shouldMarkTooEasy = await TooEasyDialog.show(
        context,
        onTooEasy: () async {
          await DatabaseService.instance
              .recordVerbProgress(widget.verb.verb_id, isTooEasy: true);
          widget.onAlreadyKnown?.call(true);
        },
        isVerb: true,
      );
      if (shouldMarkTooEasy != true) {
        return;
      }
    } else {
      await DatabaseService.instance
          .recordVerbProgress(widget.verb.verb_id, isTooEasy: true);
      widget.onAlreadyKnown?.call(true);
    }
  }

  List<TextSpan> _parseConjugation(String text) {
    final List<TextSpan> spans = [];
    final RegExp starPattern = RegExp(r'\*([^*]+)\*');
    int lastIndex = 0;

    // Vérifier si c'est un temps avec auxiliaire en comptant les mots
    // Ne pas traiter l'impératif négatif comme un temps avec auxiliaire
    final bool hasAuxiliary =
        text.trim().split(' ').length > 1 && !text.contains('no ');

    if (hasAuxiliary) {
      // Séparer l'auxiliaire et le participe passé
      final parts = text.split(' ');
      if (parts.length >= 2) {
        // Traiter l'auxiliaire
        final auxiliary = parts[0];
        // Vérifier si l'auxiliaire est entre des étoiles
        if (auxiliary.startsWith('*') && auxiliary.endsWith('*')) {
          spans.add(TextSpan(
            text: auxiliary.substring(1, auxiliary.length - 1),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: auxiliary,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ));
        }
        spans.add(const TextSpan(text: '\n')); // Retour à la ligne

        // Traiter le participe passé
        final participle = parts.sublist(1).join(' ');
        for (final match in starPattern.allMatches(participle)) {
          // Ajouter le texte avant l'étoile
          if (match.start > lastIndex) {
            spans.add(TextSpan(
              text: participle.substring(lastIndex, match.start),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ));
          }

          // Ajouter le texte entre les étoiles en gras et bleu
          spans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontSize: 16,
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
              fontSize: 16,
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
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ));
        }

        // Ajouter le texte entre les étoiles en gras et bleu
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontSize: 16,
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
            fontSize: 16,
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
                // En-tête stylisé : verbe, temps et personne
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showTranslationPopup();
                      },
                      child: Text(
                        widget.verb.verbes,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 26,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.verb.temps,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.verb.personne} (${_getPersonneDisplay(widget.verb.personne)})',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Phrase d'exemple stylisée
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], // bleu très clair
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: Colors.blue.shade300,
                        width: 5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '" ',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                children: _buildPhraseWithConjugation(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          widget.verb.phrase_fr,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  const SizedBox(height: 8),
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
                                        .recordVerbProgress(widget.verb.verb_id,
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
                                        'Je me suis trompé',
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
                                        .recordVerbProgress(widget.verb.verb_id,
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
                                        'Je savais',
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
                        if (widget.verb.nb_time_seen <= 1)
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
                                          'Trop facile (ne plus réviser)',
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
    if (widget.verb.conjugaison_complete.isEmpty) {
      return const Center(
        child: Text(
          'Aucune conjugaison disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final conjugations = widget.verb.conjugaison_complete
        .split(',')
        .map((line) => line.trim())
        .toList();

    if (conjugations.length != 6 && conjugations.length != 5) {
      return const Center(
        child: Text(
          'Format de conjugaison invalide',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (conjugations.every((conj) => conj.isEmpty)) {
      return const Center(
        child: Text(
          'Aucune conjugaison disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Trouver l'index de la personne actuelle
    final currentPersonIndex = _findCurrentPersonIndex(conjugations);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Première colonne (1ère, 2ème, 3ème personne du singulier)
                    for (int i = 0; i < (conjugations.length == 5 ? 2 : 3); i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: i == currentPersonIndex
                                ? Colors.yellow[200]
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 4),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: _parseConjugation(conjugations[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deuxième colonne (1ère, 2ème, 3ème personne du pluriel)
                    for (int i = (conjugations.length == 5 ? 2 : 3);
                        i < conjugations.length;
                        i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: i == currentPersonIndex
                                ? Colors.yellow[200]
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 4),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: _parseConjugation(conjugations[i]),
                            ),
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

  int _findCurrentPersonIndex(List<String> conjugations) {
    // Nettoyer la conjugaison actuelle pour la comparaison
    final currentConjugation =
        widget.verb.conjugaison.replaceAll('*', '').trim();

    // Chercher l'index de la conjugaison correspondante
    for (int i = 0; i < conjugations.length; i++) {
      final conjugation = conjugations[i].replaceAll('*', '').trim();
      if (conjugation == currentConjugation) {
        return i;
      }
    }

    // Si pas trouvé, retourner 0 par défaut
    return 0;
  }

  void _showTranslationPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Traduction',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.verb.traduction,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPersonneDisplay(String personne) {
    // Mapping des personnes vers leurs équivalents espagnols
    final Map<String, String> personneMapping = {
      'je': 'yo',
      'tu': 'tú',
      'il': 'él',
      'elle': 'ella',
      'nous': 'nosotros',
      'vous': 'vosotros',
      'ils': 'ellos',
      'elles': 'ellas',
    };

    return personneMapping[personne.toLowerCase()] ?? personne;
  }

  List<TextSpan> _buildPhraseWithConjugation() {
    final List<TextSpan> spans = [];
    final RegExp bracketPattern = RegExp(r'\[([^\]]*)\]');
    final match = bracketPattern.firstMatch(widget.verb.phrase_es);

    if (match == null) {
      // Pas de verbe entre crochets, afficher la phrase normale
      spans.add(TextSpan(text: widget.verb.phrase_es));
      return spans;
    }

    // Texte avant le verbe
    if (match.start > 0) {
      spans.add(TextSpan(
        text: widget.verb.phrase_es.substring(0, match.start),
      ));
    }

    // Le verbe (révélé ou "...")
    final verbText = _isRevealed ? match.group(1)! : '...';
    spans.add(TextSpan(
      text: verbText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: _isRevealed ? Colors.blue : Colors.black87,
        backgroundColor: Colors.yellow[200],
      ),
    ));

    // Texte après le verbe
    if (match.end < widget.verb.phrase_es.length) {
      spans.add(TextSpan(
        text: widget.verb.phrase_es.substring(match.end),
      ));
    }

    // Ajouter les guillemets de fermeture en bleu
    spans.add(const TextSpan(
      text: '"',
      style: TextStyle(
        fontSize: 20,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    ));

    return spans;
  }
}
