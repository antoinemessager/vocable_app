import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsDailyGoalScreen extends StatefulWidget {
  const SettingsDailyGoalScreen({super.key});

  @override
  State<SettingsDailyGoalScreen> createState() =>
      _SettingsDailyGoalScreenState();
}

class _SettingsDailyGoalScreenState extends State<SettingsDailyGoalScreen> {
  int _wordsPerDay = 5;
  int _verbsPerDay = 5;
  final _prefs = SharedPreferences.getInstance();

  String get _estimatedTime {
    // On estime environ 1-1.5 minute par mot
    final minTime = _wordsPerDay;
    final maxTime = (_wordsPerDay * 1.5).round();
    return 'Estimé $minTime-$maxTime min par jour';
  }

  String get _estimatedVerbTime {
    // On estime environ 2-3 minutes par verbe
    final minTime = _verbsPerDay * 2;
    final maxTime = _verbsPerDay * 3;
    return 'Estimé $minTime-$maxTime min par jour';
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _wordsPerDay = prefs.getInt('daily_word_goal') ?? 10;
      _verbsPerDay = prefs.getInt('daily_verb_goal') ?? 5;
    });
  }

  Future<void> _updateWordsPerDay(int value) async {
    if (value >= 1) {
      final prefs = await _prefs;
      await prefs.setInt('daily_word_goal', value);
      setState(() {
        _wordsPerDay = value;
      });
    }
  }

  Future<void> _updateVerbsPerDay(int value) async {
    if (value >= 1) {
      final prefs = await _prefs;
      await prefs.setInt('daily_verb_goal', value);
      setState(() {
        _verbsPerDay = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(_wordsPerDay),
        ),
        title: const Text(
          'Définis Tes Objectifs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Combien de nouveaux mots aimerais-tu apprendre chaque jour ?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _wordsPerDay.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        Icons.remove,
                        () => _updateWordsPerDay(_wordsPerDay - 1),
                        backgroundColor: Colors.grey[200]!,
                        iconColor: Colors.grey[700]!,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'mots par jour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        Icons.add,
                        () => _updateWordsPerDay(_wordsPerDay + 1),
                        backgroundColor: Colors.blue,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _estimatedTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Combien de nouveaux verbes aimerais-tu apprendre chaque jour ?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _verbsPerDay.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCircleButton(
                        Icons.remove,
                        () => _updateVerbsPerDay(_verbsPerDay - 1),
                        backgroundColor: Colors.grey[200]!,
                        iconColor: Colors.grey[700]!,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'verbes par jour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        Icons.add,
                        () => _updateVerbsPerDay(_verbsPerDay + 1),
                        backgroundColor: Colors.blue,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _estimatedVerbTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onPressed, {
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
