import 'package:flutter/material.dart';
import '../widgets/verb_card.dart';
import '../services/database_service.dart';
import '../models/verb.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerbScreen extends StatefulWidget {
  const VerbScreen({super.key});

  @override
  State<VerbScreen> createState() => _VerbScreenState();
}

class _VerbScreenState extends State<VerbScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  Verb _currentVerb = Verb(
    verb_id: 0,
    verb: '',
    tense: '',
    conjugation: '',
    nb_time_seen: 0,
  );
  int daily_verb_goal = 5;
  double _todayProgress = 0.0;
  double _totalMasteredVerbs = 0;
  int _dayStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadRandomVerb();
    _loadProgress();
    _loadStats();
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
    final goal = prefs.getInt('daily_verb_goal') ?? 5;
    final progress = await _databaseService.getVerbProgress();

    if (mounted) {
      setState(() {
        daily_verb_goal = goal;
        _todayProgress = progress;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final hasCompletedDailyGoal = _todayProgress >= daily_verb_goal;
    final progressPercentage =
        ((_todayProgress / daily_verb_goal) * 100).round();
    final progressValue = _todayProgress / daily_verb_goal;

    return Scaffold(
      body: Column(
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
                          hasCompletedDailyGoal ? Colors.green : Colors.blue,
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
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: VerbCard(
                      verb: _currentVerb,
                      onCorrect: (isCorrect) async {
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      Text(
                        'Appris',
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      Text(
                        'Jours',
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
      ),
    );
  }
}
