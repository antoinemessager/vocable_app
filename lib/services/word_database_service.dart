import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_pair.dart';
import '../models/word_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordDatabaseService {
  static final WordDatabaseService instance = WordDatabaseService._init();
  static Database? _database;

  WordDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception(
        'Database not initialized. Use DatabaseService.instance.database instead.');
  }

  void setDatabase(Database db) {
    _database = db;
  }

  Future<List<WordPair>> readJsonFromAssets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/words.json',
    );

    final List<dynamic> jsonData = jsonDecode(jsonString);
    List<WordPair> wordPairs = [];

    for (var entry in jsonData) {
      wordPairs.add(
        WordPair(
          word_id: entry['id'] as int? ?? 0,
          word_es: entry['mot_esp'] as String? ?? '',
          word_fr: entry['mot_fr'] as String? ?? '',
          es_sentence: entry['phrase_esp'] as String? ?? '',
          fr_sentence: entry['phrase_fr'] as String? ?? '',
          distance: (entry['distance'] as num?)?.toDouble() ?? 1.0,
        ),
      );
    }

    wordPairs.sort((a, b) => a.word_id.compareTo(b.word_id));

    return wordPairs;
  }

  // Record a new progress entry
  Future<void> recordProgress(int wordId,
      {bool isCorrect = true, bool isTooEasy = false}) async {
    final db = await database;
    final currentLevel = await getWordBoxLevel(wordId);

    int newLevel;
    if (isTooEasy) {
      newLevel = 5; // Mot considéré comme acquis
    } else if (isCorrect) {
      newLevel = currentLevel + 1;
    } else {
      newLevel = 0; // Retour au début si incorrect
    }

    final progress = WordProgress(
      wordId: wordId,
      boxLevel: newLevel,
      timestamp: DateTime.now(),
    );

    await db.insert('user_progress', progress.toMap());
  }

  // Get the latest box level for a word
  Future<int> getWordBoxLevel(int wordId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'user_progress',
      where: 'word_id = ?',
      whereArgs: [wordId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return 0;
    return WordProgress.fromMap(result.first).boxLevel;
  }

  // Get a single word for review based on the provided logic
  Future<WordPair?> getNextWordForReview() async {
    final db = await database;

    final levelRanges = {
      'A1': 1,
      'A2': 251,
      'B1': 751,
      'B2': 1501,
      'C1': 2751,
      'C2': 5001,
    };

    // Get the user's minimum level from preferences
    final prefs = await SharedPreferences.getInstance();
    final startingLevel = prefs.getString('starting_level') ?? 'A1';
    final minWordIdForLevel = levelRanges[startingLevel] ?? 1;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT
          word_id,
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
        FROM user_progress
        GROUP BY word_id
      ), UsablePairs AS (
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
        FROM vocabulary v
        LEFT JOIN UsablePairs up ON v.id = up.word_id
        WHERE v.id >= ?
          AND (up.word_id IS NOT NULL OR NOT EXISTS (
            SELECT 1 FROM user_progress up2 WHERE up2.word_id = v.id
          ))
        ORDER BY v.id
        LIMIT 50
      )
      SELECT * FROM Pool50 ORDER BY RANDOM() LIMIT 1;
    ''', [minWordIdForLevel]);

    if (results.isEmpty) {
      return null;
    }

    final map = results.first;
    return WordPair(
      word_id: map['id'],
      word_fr: map['french_word'],
      word_es: map['spanish_word'],
      fr_sentence: map['french_context'],
      es_sentence: map['spanish_context'],
      nb_time_seen: map['nb_time_seen'],
    );
  }

  // Get all words that have been seen at least twice
  Future<List<Map<String, dynamic>>> getLastStudiedWords() async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH LatestTimestamp AS (
          SELECT word_id, MAX(timestamp) AS max_timestamp
          FROM user_progress
          GROUP BY word_id
      ), EntryCounts AS (
          SELECT word_id, COUNT(*) AS nb_entries
          FROM user_progress
          GROUP BY word_id
      ), LatestTimestampEntries AS (
      SELECT 
          up.word_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = lt.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress up
      JOIN LatestTimestamp lt ON up.word_id = lt.word_id
      JOIN EntryCounts ec ON up.word_id = ec.word_id
      )
      SELECT 
        v.id as word_id,
        v.french_word,
        v.spanish_word,
        v.french_context,
        v.spanish_context,
        lp.box_level,
        lp.timestamp,
        lp.nb_entries
      FROM LatestTimestampEntries lp
      JOIN vocabulary v ON v.id = lp.word_id
      WHERE lp.rn = 1
        AND lp.nb_entries >= 2
      ORDER BY lp.timestamp DESC
    ''',
    );

    return results.map((row) {
      return {
        'word_id': row['word_id'] as int,
        'french_word': row['french_word'] as String,
        'spanish_word': row['spanish_word'] as String,
        'french_context': row['french_context'] as String,
        'spanish_context': row['spanish_context'] as String,
        'box_level': row['box_level'] as int,
        'timestamp': row['timestamp'] as String,
      };
    }).toList();
  }

  // Update a word's level manually
  Future<void> updateWordLevel(int wordId, int newLevel) async {
    final db = await database;
    final progress = WordProgress(
      wordId: wordId,
      boxLevel: newLevel,
      timestamp: DateTime.now(),
    );
    await db.insert('user_progress', progress.toMap());
  }

  Future<double> getTodayProgress() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getWordsLearnedBetweenDates(startOfDay, now);
  }

  Future<int> getDayStreak() async {
    final now = DateTime.now();
    int streak = 0;
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt('daily_word_goal') ?? 5;

    for (int i = 0;; i++) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final wordsLearned =
          await getWordsLearnedBetweenDates(startOfDay, endOfDay);
      if (wordsLearned >= dailyGoal) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  Future<double> getTotalMasteredWords() async {
    final db = await database;
    final result = await db.rawQuery('''
      WITH WordStats AS (
        SELECT 
          word_id,
          MAX(timestamp) as max_timestamp,
          COUNT(*) as nb_entries
        FROM user_progress
        GROUP BY word_id
        HAVING COUNT(*) >= 2
      )
      SELECT COALESCE(SUM(up.box_level), 0) as count
      FROM user_progress up
      JOIN WordStats ws ON up.word_id = ws.word_id 
        AND up.timestamp = ws.max_timestamp
      WHERE (up.box_level != 5 OR ws.nb_entries > 2)
    ''');
    return (result.first['count'] as int) / 5;
  }

  Future<Map<String, double>> getCEFRProgress() async {
    final db = await database;

    // Get the user's current level from preferences
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getString('starting_level') ?? 'A1';

    // Define level order for comparison
    final levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentLevelIndex = levelOrder.indexOf(currentLevel);

    final result = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            word_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress
          GROUP BY word_id
          HAVING COUNT(*) >= 2
      ), LatestInfo AS (
      SELECT 
          up.word_id,
          up.box_level,
          up.timestamp,
          ec.nb_entries
      FROM user_progress up
      JOIN EntryCounts ec 
        ON up.word_id = ec.word_id
        AND timestamp = ec.max_timestamp
      ), CEFRCounts AS (
        SELECT
          coalesce(SUM(case when word_id <= 250 then box_level else 0 end)/5, 0) as a1_count,
          coalesce(SUM(case when word_id > 250 and word_id <= 750 then box_level else 0 end)/5, 0) as a2_count,
          coalesce(SUM(case when word_id > 750 and word_id <= 1500 then box_level else 0 end)/5, 0) as b1_count,
          coalesce(SUM(case when word_id > 1500 and word_id <= 2750 then box_level else 0 end)/5, 0) as b2_count,
          coalesce(SUM(case when word_id > 2750 and word_id <= 5000 then box_level else 0 end)/5, 0) as c1_count,
          coalesce(SUM(case when word_id > 5000 then box_level else 0 end)/5, 0) as c2_count
        FROM LatestInfo
      )
      SELECT * FROM CEFRCounts
    ''');

    final counts = result.first;
    final progress = {
      'A1': (counts['a1_count'] as int) / 250.0,
      'A2': (counts['a2_count'] as int) / 500.0,
      'B1': (counts['b1_count'] as int) / 750.0,
      'B2': (counts['b2_count'] as int) / 1250.0,
      'C1': (counts['c1_count'] as int) / 2250.0,
      'C2': (counts['c2_count'] as int) / 5000.0,
    };

    // Set progress to 100% for levels below the current level
    for (int i = 0; i < currentLevelIndex; i++) {
      progress[levelOrder[i]] = 1.0;
    }

    return progress;
  }

  Future<Map<String, List<Map<String, String>>>> getAssessmentWords() async {
    final db = await database;

    // Définition des plages de word_id pour chaque niveau
    final levelRanges = {
      'A1': {'start': 1, 'end': 250},
      'A2': {'start': 251, 'end': 750},
      'B1': {'start': 751, 'end': 1500},
      'B2': {'start': 1501, 'end': 2750},
      'C1': {'start': 2751, 'end': 5000},
    };

    Map<String, List<Map<String, String>>> result = {};

    for (final level in levelRanges.keys) {
      final range = levelRanges[level]!;

      // Requête pour obtenir 10 mots aléatoires du niveau
      final List<Map<String, dynamic>> words = await db.rawQuery('''
        WITH RandomWords AS (
          SELECT 
            v.french_word as french,
            v.spanish_word as spanish,
            v.id as rank
          FROM vocabulary v
          WHERE v.id BETWEEN ? AND ?
          AND LENGTH(v.french_word) >= 3
          AND LENGTH(v.spanish_word) >= 3
          AND v.distance > 0.8
        ORDER BY RANDOM()
        LIMIT 10
        )
        SELECT * FROM RandomWords ORDER BY rank
      ''', [range['start'], range['end']]);

      // Conversion du résultat au format souhaité
      result[level] = words
          .map((word) => {
                'french': word['french'] as String,
                'spanish': word['spanish'] as String,
                'rank': word['rank'].toString(),
              })
          .toList();
    }

    return result;
  }

  Future<double> getWordsLearnedBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final db = await database;

    // Get the number of words learned before start date
    final wordsBeforeStart = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            word_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress
          WHERE timestamp < ?
          GROUP BY word_id
          HAVING COUNT(*) >= 2
      ), LatestInfo AS (
      SELECT 
          up.word_id,
          up.box_level,
          CASE WHEN ec.nb_entries=2 AND up.box_level=5 THEN 1 ELSE up.box_level END AS new_box_level,
          up.timestamp,
          ec.nb_entries
      FROM user_progress up
      JOIN EntryCounts ec 
        ON up.word_id = ec.word_id
        AND up.timestamp = ec.max_timestamp
      )
      SELECT coalesce(sum(new_box_level), 0) as learned_words
      FROM LatestInfo 
    ''', [startDate.toIso8601String()]);

    // Get the number of words learned before end date
    final wordsBeforeEnd = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            word_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress
          WHERE timestamp < ?
          GROUP BY word_id
          HAVING COUNT(*) >= 2
      ), LatestInfo AS (
      SELECT 
          up.word_id,
          up.box_level,
          CASE WHEN ec.nb_entries=2 AND up.box_level=5 THEN 1 ELSE up.box_level END AS new_box_level,
          up.timestamp,
          ec.nb_entries
      FROM user_progress up
      JOIN EntryCounts ec 
        ON up.word_id = ec.word_id
        AND up.timestamp = ec.max_timestamp
      )
      SELECT coalesce(sum(new_box_level), 0) as learned_words
      FROM LatestInfo 
    ''', [endDate.toIso8601String()]);

    final int startCount = wordsBeforeStart.first['learned_words'] as int;
    final int endCount = wordsBeforeEnd.first['learned_words'] as int;
    // Calculate progress (difference in number of words learned)
    return (endCount - startCount).toDouble() / 5;
  }

  // Get words for a specific CEFR level
  Future<List<Map<String, dynamic>>> getWordsForCEFRLevel(String level) async {
    final db = await database;

    // Get the user's current level from preferences
    final prefs = await SharedPreferences.getInstance();
    final startingLevel = prefs.getString('starting_level') ?? 'A1';

    // Define level order for comparison
    final levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentLevelIndex = levelOrder.indexOf(startingLevel);
    final requestedLevelIndex = levelOrder.indexOf(level);

    // Define the word ID ranges for each CEFR level
    final levelRanges = {
      'A1': {'start': 1, 'end': 250},
      'A2': {'start': 251, 'end': 750},
      'B1': {'start': 751, 'end': 1500},
      'B2': {'start': 1501, 'end': 2750},
      'C1': {'start': 2751, 'end': 5000},
      'C2': {'start': 5001, 'end': 10000},
    };

    final range = levelRanges[level]!;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT 
          word_id,
          box_level,
          MAX(timestamp) as latest_timestamp
        FROM user_progress
        GROUP BY word_id
      )
      SELECT 
        v.id as word_id,
        v.french_word,
        v.spanish_word,
        v.french_context,
        v.spanish_context,
        CASE 
          WHEN ? > ? THEN 5  -- If the requested level is below starting level, mark as known
          ELSE COALESCE(lp.box_level, 0)
        END as box_level
      FROM vocabulary v
      LEFT JOIN LatestProgress lp ON v.id = lp.word_id
      WHERE v.id BETWEEN ? AND ?
      ORDER BY v.id
    ''',
        [currentLevelIndex, requestedLevelIndex, range['start'], range['end']]);

    return results;
  }
}
