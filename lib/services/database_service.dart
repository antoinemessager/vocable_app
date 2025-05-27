import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_pair.dart';
import '../models/word_progress.dart';
import '../models/verb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vocable.db');

    // Vérifier si c'est le premier lancement
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch) {
      // Supprimer la base de données existante uniquement lors du premier lancement
      await databaseFactory.deleteDatabase(path);
    }

    // Créer une nouvelle base de données
    _database = await _initDB('vocable.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create vocabulary table
    await db.execute('''
      CREATE TABLE vocabulary (
        id INTEGER PRIMARY KEY,
        french_word TEXT NOT NULL,
        spanish_word TEXT NOT NULL,
        french_context TEXT NOT NULL,
        spanish_context TEXT NOT NULL
      )
    ''');

    // Create user progress table
    await db.execute('''
      CREATE TABLE user_progress (
        word_id INTEGER NOT NULL,
        box_level INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES vocabulary (id)
      )
    ''');

    // Create verb table
    await db.execute('''
      CREATE TABLE verb (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verb TEXT NOT NULL,
        tense TEXT NOT NULL,
        conjugation TEXT NOT NULL,
        UNIQUE(verb, tense)
      )
    ''');

    // Create user progress verb table
    await db.execute('''
      CREATE TABLE user_progress_verb (
        verb_id INTEGER NOT NULL,
        box_level INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (verb_id) REFERENCES verb (id)
      )
    ''');

    // Load initial vocabulary data from JSON files
    final List<WordPair> wordPairs = await readJsonFromAssets();
    final List<Map<String, dynamic>> verbs = await readVerbsFromAssets();

    final batch = db.batch();

    // Insert vocabulary words
    for (var pair in wordPairs) {
      batch.insert('vocabulary', {
        'id': pair.word_id,
        'french_word': pair.word_fr,
        'spanish_word': pair.word_es,
        'french_context': pair.fr_sentence,
        'spanish_context': pair.es_sentence,
      });
    }

    // Initialize user_progress for all words with box_level 0
    for (var pair in wordPairs) {
      batch.insert('user_progress', {
        'word_id': pair.word_id,
        'box_level': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Insert verbs
    for (var verb in verbs) {
      final verbText = verb['verb'] as String;

      // Insert each tense as a separate row
      final tenses = {
        'présent': verb['present'],
        'passé composé': verb['passe_compose'],
        'futur': verb['futur'],
        'futur antérieur': verb['futur_anterieur'],
        'imparfait': verb['imparfait'],
        'plus que parfait': verb['plus_que_parfait'],
        'passé simple': verb['passe_simple'],
        'conditionnel présent': verb['conditionnel_present'],
        'conditionnel passé': verb['conditionnel_passe'],
        'subjonctif présent': verb['subjonctif_present'],
        'subjonctif passé': verb['subjonctif_passe'],
        'impératif': verb['imperatif'],
        'impératif négatif': verb['imperatif_negatif'],
      };

      for (var entry in tenses.entries) {
        // Ne pas insérer si la conjugaison est vide ou null
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          batch.insert('verb', {
            'verb': verbText,
            'tense': entry.key,
            'conjugation': entry.value,
          });
        }
      }
    }

    // Commit the batch to insert all data
    await batch.commit(noResult: true);

    // Now that all verbs are inserted, initialize user_progress_verb
    final List<Map<String, dynamic>> insertedVerbs = await db.query('verb');
    final progressBatch = db.batch();

    for (var verb in insertedVerbs) {
      progressBatch.insert('user_progress_verb', {
        'verb_id': verb['id'],
        'box_level': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Commit the progress batch
    await progressBatch.commit(noResult: true);
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
          word_id: entry['id'] as int,
          word_es: entry['mot_esp'] as String,
          word_fr: entry['mot_fr'] as String,
          es_sentence: entry['phrase_esp'] as String,
          fr_sentence: entry['phrase_fr'] as String,
        ),
      );
    }

    wordPairs.sort((a, b) => a.word_id.compareTo(b.word_id));

    return wordPairs;
  }

  Future<List<Map<String, dynamic>>> readVerbsFromAssets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/verbes.json',
    );

    final List<dynamic> jsonData = jsonDecode(jsonString);
    final Map<String, Map<String, dynamic>> verbMap = {};

    // First pass: group conjugations by verb
    for (var entry in jsonData) {
      final verb = entry['Verbes'] as String;
      final tense = entry['Temps'] as String;
      final conjugation = entry['Conjugaison'] as String;

      // Find or create verb entry
      if (!verbMap.containsKey(verb)) {
        verbMap[verb] = {
          'verb': verb,
          'present': '',
          'passe_compose': '',
          'futur': '',
          'futur_anterieur': '',
          'imparfait': '',
          'plus_que_parfait': '',
          'passe_simple': '',
          'conditionnel_present': '',
          'conditionnel_passe': '',
          'subjonctif_present': '',
          'subjonctif_passe': '',
          'imperatif': '',
          'imperatif_negatif': '',
        };
      }

      // Map tense names to database fields
      String fieldName;
      switch (tense) {
        case 'Présent':
          fieldName = 'present';
          break;
        case 'Passé Composé':
          fieldName = 'passe_compose';
          break;
        case 'Futur':
          fieldName = 'futur';
          break;
        case 'Futur Antérieur':
          fieldName = 'futur_anterieur';
          break;
        case 'Imparfait':
          fieldName = 'imparfait';
          break;
        case 'Plus que parfait':
          fieldName = 'plus_que_parfait';
          break;
        case 'Passé Simple':
          fieldName = 'passe_simple';
          break;
        case 'Conditionnel Présent':
          fieldName = 'conditionnel_present';
          break;
        case 'Conditionnel Passé':
          fieldName = 'conditionnel_passe';
          break;
        case 'Subjonctif Présent':
          fieldName = 'subjonctif_present';
          break;
        case 'Subjonctif Passé':
          fieldName = 'subjonctif_passe';
          break;
        case 'Impératif':
          fieldName = 'imperatif';
          break;
        case 'Imperatif negatif':
          fieldName = 'imperatif_negatif';
          break;
        default:
          continue; // Skip unknown tenses
      }

      verbMap[verb]![fieldName] = conjugation;
    }

    // Convert map to list
    return verbMap.values.toList();
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
    final db = await instance.database;
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
      ), LatestInfo AS (
      SELECT 
          up.word_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.word_id = ec.word_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_words
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
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
      ), LatestInfo AS (
      SELECT 
          up.word_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.word_id = ec.word_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_words
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
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

  Future<Verb> getRandomVerb() async {
    return getNextVerbForReview();
  }

  Future<double> getVerbProgress() async {
    final db = await database;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Get the number of verbs learned before start of day
    final verbsBeforeStart = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            verb_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress_verb
          WHERE timestamp < ?
          GROUP BY verb_id
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.verb_id = ec.verb_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_verbs
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
    ''', [startOfDay.toIso8601String()]);

    // Get the number of verbs learned before now
    final verbsBeforeNow = await db.rawQuery('''
      WITH EntryCounts AS (
          SELECT 
            verb_id, 
            COUNT(*) AS nb_entries, 
            MAX(timestamp) AS max_timestamp
          FROM user_progress_verb
          WHERE timestamp < ?
          GROUP BY verb_id
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.verb_id = ec.verb_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_verbs
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
    ''', [now.toIso8601String()]);

    final int startCount = verbsBeforeStart.first['learned_verbs'] as int;
    final int nowCount = verbsBeforeNow.first['learned_verbs'] as int;

    return (nowCount - startCount).toDouble() / 5;
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
    final dailyGoal = prefs.getInt('daily_verb_goal') ?? 5;

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
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.verb_id = ec.verb_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_verbs
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
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
      ), LatestInfo AS (
      SELECT 
          up.verb_id,
          up.box_level,
          up.timestamp,
          CASE WHEN up.timestamp = ec.max_timestamp THEN 1 ELSE 2 END AS rn,
          ec.nb_entries
      FROM user_progress_verb up
      JOIN (select * from EntryCounts where nb_entries>1) ec ON up.verb_id = ec.verb_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_verbs
      FROM LatestInfo 
      where rn=1 and (box_level!=5 or nb_entries>2)
    ''', [endDate.toIso8601String()]);

    final int startCount = verbsBeforeStart.first['learned_verbs'] as int;
    final int endCount = verbsBeforeEnd.first['learned_verbs'] as int;
    // Calculate progress (difference in number of verbs learned)
    return (endCount - startCount).toDouble() / 5;
  }

  Future<Map<String, double>> getTenseProgress() async {
    final db = await database;
    final Map<String, double> progress = {};

    // Pour chaque temps verbal
    final tenses = [
      'présent',
      'futur',
      'passé composé',
      'imparfait',
      'passé simple',
      'conditionnel présent',
      'subjonctif présent',
      'subjonctif passé',
      'impératif',
      'impératif négatif',
      'plus que parfait',
      'futur antérieur',
      'conditionnel passé',
    ];

    for (var tense in tenses) {
      // Récupérer le nombre total de verbes pour ce temps
      final totalResult = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM verb
        WHERE tense = ?
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
          WHERE v.tense = ?
        ''', [tense]);

        final mastered = masteredResult.first['mastered'] as int;
        progress[tense] = mastered / total;
      } else {
        progress[tense] = 0.0;
      }
    }

    return progress;
  }

  Future<Verb> getNextVerbForReview() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final selectedTenses =
        prefs.getStringList('selected_verb_tenses') ?? ['présent'];

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
        WHERE v.tense IN (${List.filled(selectedTenses.length, '?').join(',')})
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
        verb: '',
        tense: '',
        conjugation: '',
        nb_time_seen: 0,
      );
    }
    return Verb.fromMap(result.first);
  }
}
