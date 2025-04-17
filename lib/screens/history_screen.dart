import 'package:flutter/material.dart';
import '../models/word_pair.dart';
import '../services/database_service.dart';
import '../widgets/word_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _currentIndex = 0;
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

  String _getTimeAgo(String timestamp) {
    final now = DateTime.now();
    final date = DateTime.parse(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 5) {
      return 'now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildReviewHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studyHistory.isEmpty) {
      return const Center(
        child: Text('No study history yet'),
      );
    }

    Future<void> _showLevelSelector(Map<String, dynamic> word) async {
      final levels = [
        {'level': 0, 'text': 'Unknown'},
        {'level': 1, 'text': 'Level 1'},
        {'level': 2, 'text': 'Level 2'},
        {'level': 3, 'text': 'Level 3'},
        {'level': 4, 'text': 'Level 4'},
        {'level': 5, 'text': 'Known'},
      ];
      final currentLevel = word['box_level'] as int;

      print('Debug - word map: $word'); // Debug print

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word['french_word'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                word['spanish_word'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: levels.map((level) {
                final isSelected = level['level'] == currentLevel;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      final wordId = word['word_id'] as int;
                      print(
                          'Debug - Updating word $wordId to level ${level['level']}'); // Debug print
                      await DatabaseService.instance
                          .updateWordLevel(wordId, level['level'] as int);
                      Navigator.of(context).pop();
                      _loadContent();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        level['text'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blue,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 60,
          bottom: 16,
        ),
        itemCount: _studyHistory.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Words Discovered',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${_studyHistory.length} words',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final word = _studyHistory[index - 1];
          String levelText = 'Unknown';
          if (word['box_level'] == 1) {
            levelText = 'Level 1';
          } else if (word['box_level'] == 2) {
            levelText = 'Level 2';
          } else if (word['box_level'] == 3) {
            levelText = 'Level 3';
          } else if (word['box_level'] == 4) {
            levelText = 'Level 4';
          } else if (word['box_level'] >= 5) {
            levelText = 'Known';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showLevelSelector(word),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['french_word'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          word['spanish_word'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last seen ${_getTimeAgo(word['timestamp'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            levelText,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewContent() {
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

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      children: [
        // Daily Learning Goal
        Text(
          'Daily Learning Goal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            // TODO: Implement goal adjustment
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$dailyWordGoal words per day',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Other Settings
        _buildSettingItem(
          'Notifications',
          Icons.notifications_outlined,
          onTap: () {
            // TODO: Implement notifications settings
          },
        ),
        _buildSettingItem(
          'Help Center',
          Icons.help_outline,
          onTap: () {
            // TODO: Implement help center
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem(String title, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildReviewContent(),
          _buildReviewHistory(),
          const Center(child: Text('Progress')),
          _buildSettingsContent(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
