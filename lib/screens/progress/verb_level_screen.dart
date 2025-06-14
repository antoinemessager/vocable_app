import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class VerbLevelScreen extends StatefulWidget {
  final String tense;
  final int currentVerbs;
  final int totalVerbs;

  const VerbLevelScreen({
    super.key,
    required this.tense,
    required this.currentVerbs,
    required this.totalVerbs,
  });

  @override
  State<VerbLevelScreen> createState() => _VerbLevelScreenState();
}

class _VerbLevelScreenState extends State<VerbLevelScreen> {
  List<Map<String, dynamic>> _verbs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerbs();
  }

  Future<void> _loadVerbs() async {
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT 
          verb_id,
          box_level,
          MAX(timestamp) as latest_timestamp
        FROM user_progress_verb
        GROUP BY verb_id
      )
      SELECT 
        v.id as verb_id,
        v.verb,
        v.conjugation,
        COALESCE(lp.box_level, 0) as box_level
      FROM verb v
      LEFT JOIN LatestProgress lp ON v.id = lp.verb_id
      WHERE v.tense = ?
      ORDER BY v.verb
    ''', [widget.tense]);

    setState(() {
      _verbs = results;
      _isLoading = false;
    });
  }

  String _getLevelText(int boxLevel) {
    if (boxLevel > 5) return '100%';

    switch (boxLevel) {
      case 0:
        return '0%';
      case 1:
        return '20%';
      case 2:
        return '40%';
      case 3:
        return '60%';
      case 4:
        return '80%';
      case 5:
        return '100%';
      default:
        return '0%';
    }
  }

  Color _getLevelColor(int boxLevel) {
    if (boxLevel > 5) return Colors.green;
    switch (boxLevel) {
      case 0:
        return Colors.grey;
      case 1:
      case 2:
      case 3:
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
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

  Widget _buildConjugationTable(String conjugation) {
    if (conjugation.isEmpty) {
      return const Center(
        child: Text(
          'Aucune conjugaison disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final conjugations =
        conjugation.split(',').map((line) => line.trim()).toList();

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

  void _showConjugationDialog(String verb, String conjugation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                verb,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                widget.tense,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
              _buildConjugationTable(conjugation),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.tense),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.currentVerbs / widget.totalVerbs,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.currentVerbs}/${widget.totalVerbs} verbes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liste des verbes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clique sur un verbe pour voir sa conjugaison',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ..._verbs.map((verb) {
            final boxLevel = verb['box_level'] as int;
            final color = _getLevelColor(boxLevel);
            return InkWell(
              onTap: () => _showConjugationDialog(
                verb['verb'] as String,
                verb['conjugation'] as String,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          verb['verb'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getLevelText(boxLevel),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: boxLevel / 5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
