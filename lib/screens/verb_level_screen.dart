import 'package:flutter/material.dart';
import '../services/database_service.dart';

class VerbLevelScreen extends StatefulWidget {
  final String tense;
  final int currentVerbs;
  final int totalVerbs;

  const VerbLevelScreen({
    super.key,
    required this.tense,
    required this.currentVerbs,
    required this.totalVerbs,
  });

  @override
  State<VerbLevelScreen> createState() => _VerbLevelScreenState();
}

class _VerbLevelScreenState extends State<VerbLevelScreen> {
  List<Map<String, dynamic>> _verbs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerbs();
  }

  Future<void> _loadVerbs() async {
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT 
          verb_id,
          box_level,
          MAX(timestamp) as latest_timestamp
        FROM user_progress_verb
        GROUP BY verb_id
      )
      SELECT 
        v.id as verb_id,
        v.verb,
        v.conjugation,
        COALESCE(lp.box_level, 0) as box_level
      FROM verb v
      LEFT JOIN LatestProgress lp ON v.id = lp.verb_id
      WHERE v.tense = ?
      ORDER BY v.verb
    ''', [widget.tense]);

    setState(() {
      _verbs = results;
      _isLoading = false;
    });
  }

  String _getLevelText(int boxLevel) {
    switch (boxLevel) {
      case 0:
        return '0%';
      case 1:
        return '20%';
      case 2:
        return '40%';
      case 3:
        return '60%';
      case 4:
        return '80%';
      case 5:
        return '100%';
      default:
        return '0%';
    }
  }

  Color _getLevelColor(int boxLevel) {
    switch (boxLevel) {
      case 0:
        return Colors.grey;
      case 1:
      case 2:
      case 3:
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.tense),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.currentVerbs / widget.totalVerbs,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.currentVerbs}/${widget.totalVerbs} verbes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Liste des verbes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ..._verbs.map((verb) {
            final boxLevel = verb['box_level'] as int;
            final color = _getLevelColor(boxLevel);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        verb['verb'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _getLevelText(boxLevel),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: boxLevel / 5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
