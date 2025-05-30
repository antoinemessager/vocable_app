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
import 'settings/settings_help_center_screen.dart';

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
  bool _hasShownHelp = false;
  bool _hasShownFirstPopup = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadRandomVerb();
    _loadProgress();
    _loadStats();
    _checkFirstTimeHelp();
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
        if (!_hasShownHelp && _currentVerb.verb.isNotEmpty && mounted) {
          _showFirstCardHelp();
        }
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
                  'Lis le verbe, pense à sa conjugaison au temps indiqué et appuie sur afficher la conjugaison.',
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
                      title: 'Déjà vu',
                      description:
                          'Tu connaissais déjà parfaitement la conjugaison et tu ne veux plus jamais la revoir ?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.check,
                      color: Colors.green[700]!,
                      title: 'Correct',
                      description:
                          'Tu as eu juste et tu veux continuer à réviser ce verbe ?',
                    ),
                    const SizedBox(height: 8),
                    _buildHelpItem(
                      icon: Icons.close,
                      color: Colors.red[700]!,
                      title: 'Incorrect',
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
                      child: Text(_showGoalAchieved
                          ? 'Retour à l\'accueil'
                          : 'Continuer à apprendre'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _loadRandomVerb();
                        _loadProgress();
                        _loadStats();
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
                          onShowHelp: _showAnswerHelp,
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
