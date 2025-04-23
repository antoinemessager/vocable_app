import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _totalWords = 0;
  int _dayStreak = 0;
  final Map<String, Map<String, dynamic>> _cefrProgress = {
    'A1': {'total': 250, 'current': 0},
    'A2': {'total': 500, 'current': 0},
    'B1': {'total': 750, 'current': 0},
    'B2': {'total': 1250, 'current': 0},
    'C1': {'total': 2250, 'current': 0},
    'C2': {'total': 5000, 'current': 0},
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final stats = await Future.wait([
      DatabaseService.instance.getTotalMasteredWords(),
      DatabaseService.instance.getDayStreak(),
      DatabaseService.instance.getCEFRProgress(),
    ]);

    final totalMastered = stats[0] as int;
    final Map<String, double> cefrPercentages = stats[2] as Map<String, double>;

    setState(() {
      _totalWords = totalMastered;
      _dayStreak = stats[1] as int;

      _cefrProgress['A1']!['current'] = (cefrPercentages['A1']! * 250).round();
      _cefrProgress['A2']!['current'] = (cefrPercentages['A2']! * 500).round();
      _cefrProgress['B1']!['current'] = (cefrPercentages['B1']! * 750).round();
      _cefrProgress['B2']!['current'] = (cefrPercentages['B2']! * 1250).round();
      _cefrProgress['C1']!['current'] = (cefrPercentages['C1']! * 2250).round();
      _cefrProgress['C2']!['current'] = (cefrPercentages['C2']! * 5000).round();

      _isLoading = false;
    });
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

  Widget _buildWordCount() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Center(
              child: Text(
                _totalWords.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mots Appris',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
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
        ],
      ),
    );
  }

  Widget _buildCEFRProgress() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression CEFR',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
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

  Widget _buildLevelProgress(String level) {
    final progress = _cefrProgress[level]!;
    final current = progress['current'] as int;
    final total = progress['total'] as int;
    final color = _getLevelColor(level);
    final percentage = (current / total * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          top: 60,
          bottom: 16,
        ),
        children: [
          _buildHeader(),
          _buildWordCount(),
          _buildCEFRProgress(),
        ],
      ),
    );
  }
}
