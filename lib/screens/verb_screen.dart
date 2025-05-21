import 'package:flutter/material.dart';
import '../widgets/verb_card.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerbScreen extends StatefulWidget {
  const VerbScreen({super.key});

  @override
  State<VerbScreen> createState() => _VerbScreenState();
}

class _VerbScreenState extends State<VerbScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  Map<String, dynamic> _currentVerb = {
    'verb': '',
    'tense': '',
    'conjugation': '',
    'verb_id': 0,
    'nb_time_seen': 0
  };
  int _dailyGoal = 5;
  double _todayProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRandomVerb();
    _loadProgress();
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
    final dailyGoal = prefs.getInt('daily_verb_goal') ?? 5;
    final progress = await _databaseService.getVerbProgress();

    if (mounted) {
      setState(() {
        _dailyGoal = dailyGoal;
        _todayProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCompletedDailyGoal = _todayProgress >= _dailyGoal;
    final progressPercentage = ((_todayProgress / _dailyGoal) * 100).round();
    final progressValue = _todayProgress / _dailyGoal;

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
            child: _currentVerb['verb']!.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: VerbCard(
                      verb: _currentVerb['verb']!,
                      tense: _currentVerb['tense']!,
                      conjugation: _currentVerb['conjugation']!,
                      verb_id: _currentVerb['verb_id']!,
                      nbTimeSeen: _currentVerb['nb_time_seen']!,
                      onShowConjugation: () {
                        // TODO: Show conjugation details
                      },
                      onCorrect: (isCorrect) async {
                        await _loadRandomVerb();
                        await _loadProgress();
                      },
                      onIncorrect: (isCorrect) async {
                        await _loadRandomVerb();
                        await _loadProgress();
                      },
                      onAlreadyKnown: (isTooEasy) async {
                        await _loadRandomVerb();
                        await _loadProgress();
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
