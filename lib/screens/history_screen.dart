import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _studyHistory = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

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

      final studyHistory =
          await DatabaseService.instance.getLastStudiedWords(10);

      setState(() {
        _studyHistory = studyHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> reloadContent() async {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studyHistory.isEmpty) {
      return const Center(
        child: Text('No study history yet'),
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
}
