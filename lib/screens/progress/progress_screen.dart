import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'cefr_level_screen.dart';
import 'verb_level_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _dayStreak = 0;
  int _verbDayStreak = 0;
  final Map<String, Map<String, dynamic>> _cefrProgress = {
    'A1': {'total': 250, 'current': 0},
    'A2': {'total': 500, 'current': 0},
    'B1': {'total': 750, 'current': 0},
    'B2': {'total': 1250, 'current': 0},
    'C1': {'total': 2250, 'current': 0},
    'C2': {'total': 5000, 'current': 0},
  };
  final Map<String, Map<String, dynamic>> _tenseProgress = {
    'Présent': {'total': 100, 'current': 0},
    'Futur': {'total': 100, 'current': 0},
    'Passé Composé': {'total': 100, 'current': 0},
    'Imparfait': {'total': 100, 'current': 0},
    'Passé Simple': {'total': 100, 'current': 0},
    'Conditionnel Présent': {'total': 100, 'current': 0},
    'Subjonctif Présent': {'total': 100, 'current': 0},
    'Subjonctif Passé': {'total': 100, 'current': 0},
    'Impératif': {'total': 100, 'current': 0},
    'Impératif négatif': {'total': 100, 'current': 0},
    'Plus que parfait': {'total': 100, 'current': 0},
    'Futur Antérieur': {'total': 100, 'current': 0},
    'Conditionnel Passé': {'total': 100, 'current': 0},
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await Future.wait<dynamic>([
        DatabaseService.instance.getDayStreak(),
        DatabaseService.instance.getVerbDayStreak(),
        DatabaseService.instance.getCEFRProgress(),
        DatabaseService.instance.getTenseProgress(),
      ]);

      final Map<String, double> cefrPercentages =
          stats[2] as Map<String, double>? ?? {};
      final Map<String, Map<String, int>> tenseProgress =
          stats[3] as Map<String, Map<String, int>>? ?? {};

      setState(() {
        _dayStreak = stats[0] as int? ?? 0;
        _verbDayStreak = stats[1] as int? ?? 0;

        _cefrProgress['A1']!['current'] =
            ((cefrPercentages['A1'] ?? 0.0) * 250).round();
        _cefrProgress['A2']!['current'] =
            ((cefrPercentages['A2'] ?? 0.0) * 500).round();
        _cefrProgress['B1']!['current'] =
            ((cefrPercentages['B1'] ?? 0.0) * 750).round();
        _cefrProgress['B2']!['current'] =
            ((cefrPercentages['B2'] ?? 0.0) * 1250).round();
        _cefrProgress['C1']!['current'] =
            ((cefrPercentages['C1'] ?? 0.0) * 2250).round();
        _cefrProgress['C2']!['current'] =
            ((cefrPercentages['C2'] ?? 0.0) * 5000).round();

        // Mettre à jour les progrès des temps avec les nouvelles données
        for (var entry in tenseProgress.entries) {
          if (_tenseProgress.containsKey(entry.key)) {
            final tenseData = entry.value;
            _tenseProgress[entry.key]!['current'] = tenseData['mastered'] ?? 0;
            _tenseProgress[entry.key]!['total'] = tenseData['total'] ?? 0;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          const Icon(
            Icons.bar_chart,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progression',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    if (level.startsWith('A')) return Colors.green;
    if (level.startsWith('B')) return Colors.blue;
    return Colors.purple;
  }

  Color _getTenseColor(String tense) {
    return Colors.blue;
  }

  Widget _buildCEFRProgress() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne de gauche
              Expanded(
                child: Column(
                  children: ['A1', 'B1', 'C1']
                      .map((level) => _buildLevelProgress(level))
                      .toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Colonne de droite
              Expanded(
                child: Column(
                  children: ['A2', 'B2', 'C2']
                      .map((level) => _buildLevelProgress(level))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenseProgress() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne de gauche
              Expanded(
                child: Column(
                  children: [
                    'Présent',
                    'Imparfait',
                    'Subjonctif Présent',
                    'Plus que parfait',
                    'Conditionnel Passé',
                    'Impératif négatif',
                    'Futur Antérieur',
                  ].map((tense) => _buildTenseProgressItem(tense)).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Colonne de droite
              Expanded(
                child: Column(
                  children: [
                    'Futur',
                    'Passé Composé',
                    'Passé Simple',
                    'Conditionnel Présent',
                    'Subjonctif Passé',
                    'Impératif',
                  ].map((tense) => _buildTenseProgressItem(tense)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenseProgressItem(String tense) {
    final progress = _tenseProgress[tense]!;
    final current = progress['current'] as int;
    final total = progress['total'] as int;
    final color = _getTenseColor(tense);
    final percentage = total > 0 ? (current / total * 100).round() : 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerbLevelScreen(
              tense: tense,
              currentVerbs: current,
              totalVerbs: total,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        height: 102,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tense,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? current / total : 0.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$current/$total conjugaisons',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(String level) {
    final progress = _cefrProgress[level]!;
    final current = progress['current'] as int;
    final total = progress['total'] as int;
    final color = _getLevelColor(level);
    final percentage = (current / total * 100).round();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CEFRLevelScreen(
              level: level,
              currentWords: current,
              totalWords: total,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$current/$total mots',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
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
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 40,
          bottom: 16,
        ),
        children: [
          _buildHeader(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vocabulaire',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Série de $_dayStreak jours',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCEFRProgress(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conjugaison',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Série de $_verbDayStreak jours',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTenseProgress(),
        ],
      ),
    );
  }
}
