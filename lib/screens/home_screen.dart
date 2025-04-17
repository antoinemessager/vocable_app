import 'package:flutter/material.dart';
import '../models/word_pair.dart';
import '../services/database_service.dart';
import '../widgets/word_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WordPair? _currentWord;
  List<Map<String, dynamic>> _studyHistory = [];
  bool _isLoading = true;
  double _todayProgress = 0.0;
  final int dailyWordGoal = 10;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final nextWord = await DatabaseService.instance.getNextWordForReview();
      final studyHistory =
          await DatabaseService.instance.getLastStudiedWords(10);
      final todayProgress = await DatabaseService.instance.getTodayProgress();

      setState(() {
        _currentWord = nextWord;
        _studyHistory = studyHistory;
        _todayProgress = todayProgress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getNextWord() async {
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWord == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No words to review right now',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getNextWord,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber[700],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Progress",
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${((_todayProgress / dailyWordGoal) * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _todayProgress / dailyWordGoal,
                    minHeight: 16,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  WordCard(
                    word: _currentWord!,
                    onAnswer: (wasCorrect) async {
                      await DatabaseService.instance.recordProgress(
                        _currentWord!.word_id,
                        isCorrect: wasCorrect,
                      );
                      _getNextWord();
                    },
                    onTooEasy: () async {
                      await DatabaseService.instance.recordProgress(
                        _currentWord!.word_id,
                        isTooEasy: true,
                      );
                      _getNextWord();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      _studyHistory
                          .where((word) => word['box_level'] >= 5)
                          .length
                          .toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                    Text(
                      'Mastered',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                    Text(
                      'Day Streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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
