import 'package:flutter/material.dart';
import '../widgets/verb_card.dart';
import '../services/database_service.dart';
import '../models/verb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/star_animation.dart';
import '../widgets/calendar_animation.dart';
import '../services/preferences_service.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import '../screens/main_screen.dart';

class VerbScreen extends StatefulWidget {
  const VerbScreen({super.key});

  @override
  State<VerbScreen> createState() => _VerbScreenState();
}

class _VerbScreenState extends State<VerbScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final PreferencesService _preferencesService = PreferencesService();
  late ConfettiController _confettiController;
  Verb _currentVerb = Verb(
    verb_id: 0,
    verb: '',
    tense: '',
    conjugation: '',
    nb_time_seen: 0,
  );
  int daily_verb_goal = 2;
  double _todayProgress = 0.0;
  double _totalMasteredVerbs = 0;
  int _dayStreak = 0;
  bool _showStarAnimation = false;
  double _currentMasteredCount = 0;
  final GlobalKey _masteredKey = GlobalKey();
  final GlobalKey _streakKey = GlobalKey();
  bool _showGoalAchieved = false;
  bool _showCalendarAnimation = false;
  int _currentStreakCount = 0;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadRandomVerb();
    _loadProgress();
    _loadStats();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRandomVerb() async {
    final verb = await _databaseService.getRandomVerb();

    if (mounted) {
      setState(() {
        _currentVerb = verb;
      });
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('daily_verb_goal') ?? 2;
    final progress = await _databaseService.getVerbProgress();
    _previousProgress = await _preferencesService.getPreviousVerbProgress();

    // Vérifier si l'utilisateur vient de dépasser 100% de son objectif pour la première fois
    final bool hasJustExceededGoal =
        _previousProgress < daily_verb_goal && progress >= daily_verb_goal;

    if (mounted) {
      setState(() {
        daily_verb_goal = goal;
        _todayProgress = progress;
        _showGoalAchieved = hasJustExceededGoal;
        if (hasJustExceededGoal) {
          MainScreen.updateProgress();
        }
      });
    }

    // Sauvegarder la nouvelle valeur de progression
    await _preferencesService.setPreviousVerbProgress(progress);
    _previousProgress = progress;
  }

  void _startStarAnimation() async {
    final totalMasteredVerbs = await _databaseService.getTotalMasteredVerbs();
    setState(() {
      _showStarAnimation = true;
      _currentMasteredCount = totalMasteredVerbs;
    });
  }

  Future<void> _loadStats() async {
    final totalMastered = await _databaseService.getTotalMasteredVerbs();
    final streak = await _databaseService.getVerbDayStreak();

    if (mounted) {
      setState(() {
        _totalMasteredVerbs = totalMastered;
        _dayStreak = streak;
      });
    }
  }

  void _startCalendarAnimation() {
    setState(() {
      _showCalendarAnimation = true;
      _currentStreakCount = _dayStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Afficher le chargement uniquement pendant l'initialisation
    if (_currentVerb.verb.isEmpty &&
        _todayProgress == 0.0 &&
        _totalMasteredVerbs == 0) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasCompletedDailyGoal = _todayProgress >= daily_verb_goal;
    final progressPercentage =
        ((_todayProgress / daily_verb_goal) * 100).round();
    final progressValue = _todayProgress / daily_verb_goal;

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
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showGoalAchieved = false;
                      });
                      _startCalendarAnimation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Continuer à apprendre'),
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

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),
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
                                  "Progression",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '$progressPercentage%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: hasCompletedDailyGoal
                                            ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 16,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
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
              Expanded(
                child: _currentVerb.verb.isEmpty
                    ? Center(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Pas de verbes à réviser pour le moment. Tu peux modifier la liste des temps à réviser dans les paramètres.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: VerbCard(
                          verb: _currentVerb,
                          onCorrect: (isCorrect) async {
                            final totalMastered =
                                await _databaseService.getTotalMasteredVerbs();
                            if (totalMastered.toInt() >
                                _totalMasteredVerbs.toInt()) {
                              _startStarAnimation();
                            }
                            await _loadRandomVerb();
                            await _loadProgress();
                            await _loadStats();
                          },
                          onIncorrect: (isCorrect) async {
                            await _loadRandomVerb();
                            await _loadProgress();
                            await _loadStats();
                          },
                          onAlreadyKnown: (isTooEasy) async {
                            await _loadRandomVerb();
                            await _loadProgress();
                            await _loadStats();
                          },
                        ),
                      ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            _totalMasteredVerbs.toInt().toString(),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          const Icon(Icons.calendar_today,
                              color: Colors.blue, size: 28),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}
