import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onPageChanged;

  const HomeScreen({
    super.key,
    required this.onPageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  double _wordProgress = 0.0;
  double _verbProgress = 0.0;
  int _wordGoal = 3;
  int _verbGoal = 2;
  int _wordDayStreak = 0;
  int _verbDayStreak = 0;
  double _totalMasteredWords = 0.0;
  double _totalMasteredVerbs = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final wordGoal = prefs.getInt('daily_word_goal') ?? 3;
    final verbGoal = prefs.getInt('daily_verb_goal') ?? 2;

    final wordProgress = await DatabaseService.instance.getTodayProgress();
    final verbProgress = await DatabaseService.instance.getVerbProgress();
    final wordDayStreak = await DatabaseService.instance.getDayStreak();
    final verbDayStreak = await DatabaseService.instance.getVerbDayStreak();
    final totalMasteredWords =
        await DatabaseService.instance.getTotalMasteredWords();
    final totalMasteredVerbs =
        await DatabaseService.instance.getTotalMasteredVerbs();

    setState(() {
      _wordProgress = wordProgress;
      _verbProgress = verbProgress;
      _wordGoal = wordGoal;
      _verbGoal = verbGoal;
      _wordDayStreak = wordDayStreak;
      _verbDayStreak = verbDayStreak;
      _totalMasteredWords = totalMasteredWords;
      _totalMasteredVerbs = totalMasteredVerbs;
      _isLoading = false;
    });
  }

  Widget _buildProgressCard({
    required String title,
    required IconData icon,
    required Color color,
    required double progress,
    required int goal,
    required int dayStreak,
    required double totalMastered,
    required VoidCallback onTap,
  }) {
    final bool hasCompletedGoal = progress >= goal;
    final percentage = ((progress / goal) * 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '$percentage% de l\'objectif',
                          style: TextStyle(
                            color:
                                hasCompletedGoal ? Colors.green : Colors.blue,
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
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / goal,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hasCompletedGoal ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.round()}/$goal',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$dayStreak jours de suite',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title == 'Vocabulaire'
                            ? 'Mots appris'
                            : title == 'Conjugaison'
                                ? 'Verbes appris'
                                : 'Total appris',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            totalMastered.round().toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasCompletedGoal ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 8),
                      ),
                      child: Text(hasCompletedGoal
                          ? 'Objectif atteint !'
                          : 'Apprendre'),
                    ),
                  ),
                ],
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
      body: ListView(
        padding: const EdgeInsets.only(top: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.school,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Bienvenue !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressCard(
            title: 'Vocabulaire',
            icon: Icons.menu_book,
            color: Colors.blue,
            progress: _wordProgress,
            goal: _wordGoal,
            dayStreak: _wordDayStreak,
            totalMastered: _totalMasteredWords,
            onTap: () {
              widget.onPageChanged(1);
            },
          ),
          _buildProgressCard(
            title: 'Conjugaison',
            icon: Icons.edit_note,
            color: Colors.blue,
            progress: _verbProgress,
            goal: _verbGoal,
            dayStreak: _verbDayStreak,
            totalMastered: _totalMasteredVerbs,
            onTap: () {
              widget.onPageChanged(2);
            },
          ),
        ],
      ),
    );
  }
}
