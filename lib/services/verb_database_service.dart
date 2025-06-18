import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../models/verb.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerbDatabaseService {
  static final VerbDatabaseService instance = VerbDatabaseService._init();
  static Database? _database;

  VerbDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception(
        'Database not initialized. Use DatabaseService.instance.database instead.');
  }

  void setDatabase(Database db) {
    _database = db;
  }

  Future<List<Map<String, dynamic>>> readVerbsFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/verbes.json',
      );

      final List<dynamic> jsonData = jsonDecode(jsonString);
      List<Map<String, dynamic>> verbs = [];

      for (var entry in jsonData) {
        if (entry is Map<String, dynamic>) {
          verbs.add({
            'verbes': entry['verbes'] as String? ?? '',
            'temps': entry['temps'] as String? ?? '',
            'traduction': entry['traduction'] as String? ?? '',
            'conjugaison_complete':
                entry['conjugaison_complete'] as String? ?? '',
            'conjugaison': entry['conjugaison'] as String? ?? '',
            'personne': entry['personne'] as String? ?? '',
            'phrase_es': entry['phrase_es'] as String? ?? '',
            'phrase_fr': entry['phrase_fr'] as String? ?? '',
          });
        }
      }

      return verbs;
    } catch (e) {
      print('Erreur lors de la lecture du fichier verbes.json: $e');
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }

  Future<Verb> getRandomVerb() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final selectedTenses =
        prefs.getStringList('selected_verb_tenses') ?? ['Présent'];

    // Les temps sélectionnés correspondent maintenant directement aux temps dans le JSON
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT
          verb_id,
          box_level,
          MAX(timestamp) AS latest_timestamp,
          CASE
            WHEN box_level = 1 THEN datetime(timestamp, '+1 hour')
            WHEN box_level = 2 THEN datetime(timestamp, '+1 day')
            WHEN box_level = 3 THEN datetime(timestamp, '+3 days')
            WHEN box_level = 4 THEN datetime(timestamp, '+7 days')
            WHEN box_level = 5 THEN datetime(timestamp, '+10 years')
            ELSE timestamp
          END AS min_timestamp,
          COUNT(*) AS nb_time_seen
        FROM user_progress_verb
        GROUP BY verb_id
      ), UsableVerbs AS (
        SELECT
          lp.*
        FROM LatestProgress lp
        WHERE datetime('now') >= lp.min_timestamp
          OR lp.box_level = 0
      ), Pool50 AS (
        SELECT
          v.*,
          COALESCE(up.box_level, 0) as box_level,
          COALESCE(up.nb_time_seen, 0) as nb_time_seen
        FROM verb v
        LEFT JOIN UsableVerbs up ON v.id = up.verb_id
        WHERE v.temps IN (${List.filled(selectedTenses.length, '?').join(',')})
          AND (up.verb_id IS NOT NULL OR NOT EXISTS (
            SELECT 1 FROM user_progress_verb up2 WHERE up2.verb_id = v.id
          ))
        ORDER BY v.id
        LIMIT 50
      )
      SELECT * FROM Pool50 ORDER BY RANDOM() LIMIT 1;
    ''', selectedTenses);

    if (result.isEmpty) {
      return Verb(
        verb_id: 0,
        verbes: '',
        temps: '',
        traduction: '',
        conjugaison_complete: '',
        conjugaison: '',
        personne: '',
        phrase_es: '',
        phrase_fr: '',
        nb_time_seen: 0,
      );
    }
    return Verb.fromMap(result.first);
  }

  Future<double> getVerbProgress() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getVerbProgressBetweenDates(startOfDay, now);
  }

  Future<void> recordVerbProgress(int verbId,
      {bool isCorrect = true, bool isTooEasy = false}) async {
    final db = await database;
    final currentLevel = await getVerbBoxLevel(verbId);

    int newLevel;
    if (isTooEasy) {
      newLevel = 5; // Verbe considéré comme acquis
    } else if (isCorrect) {
      newLevel = currentLevel + 1;
    } else {
      newLevel = 0; // Retour au début si incorrect
    }

    await db.insert('user_progress_verb', {
      'verb_id': verbId,
      'box_level': newLevel,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getVerbBoxLevel(int verbId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'user_progress_verb',
      where: 'verb_id = ?',
      whereArgs: [verbId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0;
    return result.first['box_level'] as int;
  }

  Future<double> getTotalMasteredVerbs() async {
    final db = await database;
    final result = await db.rawQuery('''
      WITH VebStats AS (
        SELECT 
          verb_id,
          MAX(timestamp) as max_timestamp,
          COUNT(*) as nb_entries
        FROM user_progress_verb
        GROUP BY verb_id
        HAVING COUNT(*) >= 2
      )
      SELECT COALESCE(SUM(up.box_level), 0) as count
      FROM user_progress_verb up
      JOIN VebStats vs ON up.verb_id = vs.verb_id 
        AND up.timestamp = vs.max_timestamp
      WHERE (up.box_level != 5 OR vs.nb_entries > 2)
    ''');
    return (result.first['count'] as int).toDouble() / 5;
  }

  Future<int> getVerbDayStreak() async {
    final now = DateTime.now();
    int streak = 0;
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt('daily_verb_goal') ?? 2;

    for (int i = 0;; i++) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final verbsLearned =
          await getVerbProgressBetweenDates(startOfDay, endOfDay);
      if (verbsLearned >= dailyGoal) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  Future<double> getVerbProgressBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final db = await database;

    // Get the number of verbs learned before start date
    final verbsBeforeStart = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            verb_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress_verb
          WHERE timestamp < ?
          GROUP BY verb_id
          HAVING COUNT(*) >= 2
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          CASE WHEN ec.nb_entries=2 AND up.box_level=5 THEN 1 ELSE up.box_level END AS new_box_level,
          up.timestamp,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN EntryCounts ec 
        ON up.verb_id = ec.verb_id
        AND up.timestamp = ec.max_timestamp
      )
      SELECT coalesce(sum(new_box_level), 0) as learned_verbs
      FROM LatestInfo 
    ''', [startDate.toIso8601String()]);

    // Get the number of verbs learned before end date
    final verbsBeforeEnd = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            verb_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress_verb
          WHERE timestamp < ?
          GROUP BY verb_id
          HAVING COUNT(*) >= 2
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          CASE WHEN ec.nb_entries=2 AND up.box_level=5 THEN 1 ELSE up.box_level END AS new_box_level,
          up.timestamp,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN EntryCounts ec 
        ON up.verb_id = ec.verb_id
        AND up.timestamp = ec.max_timestamp
      )
      SELECT coalesce(sum(new_box_level), 0) as learned_verbs
      FROM LatestInfo 
    ''', [endDate.toIso8601String()]);

    final int startCount = verbsBeforeStart.first['learned_verbs'] as int;
    final int endCount = verbsBeforeEnd.first['learned_verbs'] as int;
    // Calculate progress (difference in number of verbs learned)
    return (endCount - startCount).toDouble() / 5;
  }

  Future<Map<String, Map<String, int>>> getTenseProgress() async {
    final db = await database;
    final Map<String, Map<String, int>> progress = {};

    // Pour chaque temps verbal (avec les noms exacts du JSON)
    final tenses = [
      'Conditionnel Passé',
      'Conditionnel Présent',
      'Futur',
      'Futur Antérieur',
      'Imparfait',
      'Impératif négatif',
      'Impératif',
      'Passé Composé',
      'Passé Simple',
      'Plus que parfait',
      'Présent',
      'Subjonctif Passé',
      'Subjonctif Présent'
    ];

    for (var tense in tenses) {
      // Récupérer le nombre total de verbes pour ce temps
      final totalResult = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM verb
        WHERE temps = ?
      ''', [tense]);

      final total = totalResult.first['total'] as int;

      if (total > 0) {
        // Récupérer le nombre de verbes maîtrisés pour ce temps
        final masteredResult = await db.rawQuery('''
          WITH LatestProgress AS (
            SELECT
              verb_id,
              box_level,
              MAX(timestamp) AS latest_timestamp
            FROM user_progress_verb
            GROUP BY verb_id
          )
          SELECT sum(box_level)/5 as mastered
          FROM verb v
          JOIN LatestProgress lp ON v.id = lp.verb_id
          WHERE v.temps = ?
        ''', [tense]);

        final mastered = masteredResult.first['mastered'] as int;
        progress[tense] = {
          'total': total,
          'mastered': mastered,
        };
      } else {
        progress[tense] = {
          'total': 0,
          'mastered': 0,
        };
      }
    }
    return progress;
  }

  Future<int> insertVerb(Verb verb) async {
    final db = await database;
    return await db.insert('verb', {
      'verbes': verb.verbes,
      'temps': verb.temps,
      'traduction': verb.traduction,
      'conjugaison_complete': verb.conjugaison_complete,
      'conjugaison': verb.conjugaison,
      'personne': verb.personne,
      'phrase_es': verb.phrase_es,
      'phrase_fr': verb.phrase_fr,
    });
  }

  Future<void> insertVerbs(List<Map<String, dynamic>> verbs) async {
    final db = await database;
    for (var verbData in verbs) {
      await db.insert('verb', {
        'verbes': verbData['verbes'],
        'temps': verbData['temps'],
        'traduction': verbData['traduction'],
        'conjugaison_complete': verbData['conjugaison_complete'],
        'conjugaison': verbData['conjugaison'],
        'personne': verbData['personne'],
        'phrase_es': verbData['phrase_es'],
        'phrase_fr': verbData['phrase_fr'],
      });
    }
  }

  Future<Verb> getFirstVerb() async {
    final db = await database;
    final result = await db.rawQuery('''
      select *
      from verb
      where id=1
    ''');

    if (result.isEmpty) {
      return Verb(
        verb_id: 0,
        verbes: '',
        temps: '',
        traduction: '',
        conjugaison_complete: '',
        conjugaison: '',
        personne: '',
        phrase_es: '',
        phrase_fr: '',
        nb_time_seen: 0,
      );
    }
    return Verb.fromMap(result.first);
  }
}
