import 'package:flutter/material.dart';
import '../models/word_pair.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../widgets/word_card.dart';
import '../widgets/star_animation.dart';

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
  int _dailyWordGoal = 10;
  int _dayStreak = 0;
  int _totalMasteredWords = 0;
  final PreferencesService _preferencesService = PreferencesService();
  bool _showStarAnimation = false;
  int _currentMasteredCount = 0;
  final GlobalKey _masteredKey = GlobalKey();
  final GlobalKey _streakKey = GlobalKey();
  double _previousProgress = 0.0;
  bool _showGoalAchieved = false;

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

      _dailyWordGoal = await _preferencesService.getDailyWordGoal();
      final nextWord = await DatabaseService.instance.getNextWordForReview();
      final studyHistory = await DatabaseService.instance.getLastStudiedWords();
      final todayProgress = await DatabaseService.instance.getTodayProgress();
      final dayStreak = await DatabaseService.instance.getDayStreak();
      final totalMasteredWords =
          await DatabaseService.instance.getTotalMasteredWords();

      _previousProgress = await _preferencesService.getPreviousProgress();

      // Vérifier si l'utilisateur vient de dépasser 100% de son objectif pour la première fois
      final bool hasJustExceededGoal =
          _previousProgress < _dailyWordGoal && todayProgress >= _dailyWordGoal;
      final bool isFirstTime = await _preferencesService.getIsFirstTimeGoal();

      setState(() {
        _currentWord = nextWord;
        _studyHistory = studyHistory;
        _todayProgress = todayProgress;
        _dayStreak = dayStreak;
        _totalMasteredWords = totalMasteredWords;
        _isLoading = false;
        if (hasJustExceededGoal && isFirstTime) {
          _showGoalAchieved = true;
          _preferencesService.setIsFirstTimeGoal(false);
        }
      });

      // Sauvegarder la nouvelle valeur de progression
      await _preferencesService.setPreviousProgress(todayProgress);
      _previousProgress = todayProgress;
    } catch (e) {
      print('Erreur lors du chargement du contenu : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getNextWord() async {
    await _loadContent();
  }

  void _startStarAnimation() {
    setState(() {
      _showStarAnimation = true;
      _currentMasteredCount =
          _studyHistory.where((word) => word['box_level'] >= 5).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showGoalAchieved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                'Objectif atteint !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Félicitations, tu as atteint ton objectif quotidien !',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGoalAchieved = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Continuer à apprendre'),
              ),
            ],
          ),
        ),
      );
    }

    final bool hasCompletedDailyGoal = _todayProgress >= _dailyWordGoal;

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
              'Tout est à jour !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pas de mots à réviser pour le moment',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _getNextWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Progression",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  '${((_todayProgress / _dailyWordGoal) * 100).round()}%',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color:
                                                            hasCompletedDailyGoal
                                                                ? Colors.green
                                                                : Colors.blue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value:
                                                _todayProgress / _dailyWordGoal,
                                            minHeight: 16,
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              hasCompletedDailyGoal
                                                  ? Colors.green
                                                  : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: WordCard(
                                  word: _currentWord!,
                                  onAnswer: (wasCorrect) async {
                                    final currentLevel = await DatabaseService
                                        .instance
                                        .getWordBoxLevel(_currentWord!.word_id);
                                    await DatabaseService.instance
                                        .recordProgress(
                                      _currentWord!.word_id,
                                      isCorrect: wasCorrect,
                                    );
                                    if (wasCorrect && currentLevel == 4) {
                                      final wordHistory =
                                          _studyHistory.firstWhere(
                                        (word) =>
                                            word['word_id'] ==
                                            _currentWord!.word_id,
                                        orElse: () =>
                                            {'nb_entries': 0, 'box_level': 0},
                                      );
                                      if (wordHistory['nb_entries'] > 2 &&
                                          wordHistory['box_level'] >= 5) {
                                        _startStarAnimation();
                                      }
                                    }
                                    _getNextWord();
                                  },
                                  onTooEasy: () async {
                                    await DatabaseService.instance
                                        .recordProgress(
                                      _currentWord!.word_id,
                                      isTooEasy: true,
                                    );
                                    _getNextWord();
                                  },
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  key: _masteredKey,
                                  width: 120,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 28),
                                      const SizedBox(height: 4),
                                      Text(
                                        _totalMasteredWords.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                      ),
                                      Text(
                                        'Appris',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  key: _streakKey,
                                  width: 120,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dayStreak.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                      ),
                                      Text(
                                        'Jours de suite',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_showStarAnimation)
          StarAnimation(
            currentCount: _currentMasteredCount,
            masteredKey: _masteredKey,
            onComplete: () {
              setState(() {
                _showStarAnimation = false;
              });
            },
          ),
      ],
    );
  }
}
