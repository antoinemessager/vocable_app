import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/level_selector_dialog.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      final studyHistory = await DatabaseService.instance.getLastStudiedWords();
      setState(() {
        _studyHistory = studyHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du contenu : $e');
      setState(() => _isLoading = false);
    }
  }

  String _getTimeAgo(String timestamp) {
    final now = DateTime.now();
    final date = DateTime.parse(timestamp);
    final difference = now.difference(date);

    if (difference.inSeconds < 5) return 'maintenant';
    if (difference.inMinutes < 1)
      return 'il y a ${difference.inSeconds} secondes';
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'il y a $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'il y a $hours ${hours == 1 ? 'heure' : 'heures'}';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'il y a $days ${days == 1 ? 'jour' : 'jours'}';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'il y a $weeks ${weeks == 1 ? 'semaine' : 'semaines'}';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'il y a $months ${months == 1 ? 'mois' : 'mois'}';
    }
    final years = (difference.inDays / 365).floor();
    return 'il y a $years ${years == 1 ? 'an' : 'ans'}';
  }

  Future<void> _showLevelSelector(Map<String, dynamic> word) async {
    await showDialog(
      context: context,
      builder: (context) => LevelSelectorDialog(
        word: word,
        onLevelChanged: _loadContent,
      ),
    );
  }

  String _getLevelText(int boxLevel) {
    switch (boxLevel) {
      case 1:
        return 'Niveau 1';
      case 2:
        return 'Niveau 2';
      case 3:
        return 'Niveau 3';
      case 4:
        return 'Niveau 4';
      case >= 5:
        return 'Connu';
      default:
        return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studyHistory.isEmpty) {
      return const Center(
        child: Text('Aucun historique d\'étude pour le moment'),
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
                  const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mots Découverts',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${_studyHistory.length} mots',
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
                          style: const TextStyle(
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
                          'Vu ${_getTimeAgo(word['timestamp'])}',
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
                            _getLevelText(word['box_level']),
                            style: const TextStyle(
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
