import 'package:flutter/material.dart';
import '../models/word_pair.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../widgets/word_card.dart';
import '../widgets/star_animation.dart';
import '../widgets/calendar_animation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import 'settings/settings_help_center_screen.dart';
import 'main_screen.dart';

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  WordPair? _currentWord;
  bool _isLoading = true;
  double _todayProgress = 0.0;
  int daily_word_goal = 5;
  int _dayStreak = 0;
  double _totalMasteredWords = 0.0;
  final PreferencesService _preferencesService = PreferencesService();
  bool _showStarAnimation = false;
  double _currentMasteredCount = 0;
  final GlobalKey _masteredKey = GlobalKey();
  final GlobalKey _streakKey = GlobalKey();
  double _previousProgress = 0.0;
  bool _showGoalAchieved = false;
  bool _hasShownHelp = false;
  bool _hasShownFirstPopup = false;
  bool _showCalendarAnimation = false;
  int _currentStreakCount = 0;
  late ConfettiController _confettiController;
  bool _isGoalReached = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadContent();
    _checkFirstTimeHelp();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeHelp() async {
    _hasShownHelp = await _preferencesService.getHasShownHelp();
  }

  void _showFirstCardHelp() {
    if (!_hasShownHelp) {
      _hasShownFirstPopup = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Fonctionnement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Traduis en espagnol et dans ta tête le mot affiché puis clique sur "Afficher la traduction"',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showAnswerHelp() {
    if (!_hasShownHelp && _hasShownFirstPopup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Où cliquer?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(
                      icon: Icons.double_arrow,
                      color: Colors.grey[700]!,
                      title: 'Trop facile',
                      description:
                          'Tu connaissais déjà parfaitement le mot et tu n\'as pas besoin de le réviser?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.check,
                      color: Colors.green[700]!,
                      title: 'Je savais',
                      description:
                          'Tu as eu juste et tu veux continuer à le réviser ?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.close,
                      color: Colors.red[700]!,
                      title: 'Je me suis trompé',
                      description: 'Tu t\'es trompé ?',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasShownHelp,
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() {
                                _hasShownHelp = value;
                              });
                              await _preferencesService.setHasShownHelp(value);
                            }
                          },
                        ),
                        const Text('Ne plus voir'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsHelpCenterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('En savoir plus'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _loadContent() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      daily_word_goal = prefs.getInt('daily_word_goal') ?? 3;
      final nextWord = await DatabaseService.instance.getNextWordForReview();
      final todayProgress = await DatabaseService.instance.getTodayProgress();
      final dayStreak = await DatabaseService.instance.getDayStreak();
      final totalMasteredWords =
          await DatabaseService.instance.getTotalMasteredWords();
      _previousProgress = await _preferencesService.getPreviousWordProgress();

      // Vérifier si l'utilisateur vient de dépasser 100% de son objectif pour la première fois
      final bool hasJustExceededGoal = _previousProgress < daily_word_goal &&
          todayProgress >= daily_word_goal;

      if (!mounted) return;
      setState(() {
        _currentWord = nextWord;
        _todayProgress = todayProgress;
        _dayStreak = dayStreak;
        _totalMasteredWords = totalMasteredWords;
        _isLoading = false;
        _showGoalAchieved = false;
        if (hasJustExceededGoal) {
          _showGoalAchieved = true;
          MainScreen.updateProgress();
        }
        _isGoalReached = todayProgress >= daily_word_goal;
      });

      // Sauvegarder la nouvelle valeur de progression
      await _preferencesService.setPreviousWordProgress(todayProgress);
      _previousProgress = todayProgress;

      // Afficher le premier pop-up d'aide si nécessaire
      if (!_hasShownHelp && _currentWord != null && mounted) {
        _showFirstCardHelp();
      }
    } catch (e) {
      print('Erreur lors du chargement du contenu : $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getNextWord() async {
    if (!mounted) return;
    await _loadContent();
  }

  void _startStarAnimation() async {
    if (!mounted) return;
    final totalMasteredWords =
        await DatabaseService.instance.getTotalMasteredWords();
    if (!mounted) return;
    setState(() {
      _showStarAnimation = true;
      _currentMasteredCount = totalMasteredWords;
    });
  }

  void _startCalendarAnimation() {
    if (!mounted) return;
    setState(() {
      _showCalendarAnimation = true;
      _currentStreakCount = _dayStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showGoalAchieved) {
      _confettiController.play();
      return Stack(
        children: [
          Center(
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        MainScreen.updateProgress();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isGoalReached
                          ? 'Retour à l\'accueil'
                          : 'Continuer à apprendre'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _startCalendarAnimation();
                        _getNextWord();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      child: const Text('Continuer à apprendre'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      );
    }

    final bool hasCompletedDailyGoal = _todayProgress >= daily_word_goal;

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
            const SizedBox(height: 40),
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
                                                  '${((_todayProgress / daily_word_goal) * 100).round()}%',
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
                                            value: _todayProgress /
                                                daily_word_goal,
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
                                    await DatabaseService.instance
                                        .recordProgress(
                                      _currentWord!.word_id,
                                      isCorrect: wasCorrect,
                                    );
                                    final totalMasteredWords =
                                        await DatabaseService.instance
                                            .getTotalMasteredWords();
                                    if (totalMasteredWords.toInt() >
                                        _totalMasteredWords.toInt()) {
                                      _startStarAnimation();
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
                                  onShowTranslation: () {
                                    _showAnswerHelp();
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
                                        _totalMasteredWords.toInt().toString(),
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
                                        'Jours',
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
            currentCount: _currentMasteredCount.toInt(),
            masteredKey: _masteredKey,
            onComplete: () {
              setState(() {
                _showStarAnimation = false;
              });
            },
          ),
        if (_showCalendarAnimation)
          CalendarAnimation(
            currentCount: _currentStreakCount,
            calendarKey: _streakKey,
            onComplete: () {
              setState(() {
                _showCalendarAnimation = false;
              });
            },
          ),
      ],
    );
  }
}
