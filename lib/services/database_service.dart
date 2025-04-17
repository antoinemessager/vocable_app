import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_pair.dart';
import '../models/word_progress.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vocable.db');

    // Supprimer la base de données existante
    await databaseFactory.deleteDatabase(path);

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

    // Load initial vocabulary data from JSON file
    final List<WordPair> wordPairs = await readJsonFromAssets();
    final batch = db.batch();

    // Insert vocabulary words
    for (var pair in wordPairs) {
      batch.insert('vocabulary', pair.toMap());
    }

    // Initialize user_progress for all words with box_level 0
    for (var pair in wordPairs) {
      batch.insert('user_progress', {
        'word_id': pair.word_id,
        'box_level': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<WordPair>> readJsonFromAssets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/words.json',
    );

    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    List<WordPair> wordPairs = [];
    jsonData.forEach((key, value) {
      wordPairs.add(
        WordPair(
          word_id: value['rank'] ?? 0,
          word_es: value['es_word'] ?? 'ERROR',
          word_fr: value['fr_word'] ?? 'ERROR',
          es_sentence: value['es_sentence'] ?? '',
          fr_sentence: value['fr_sentence'] ?? '',
        ),
      );
    });

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
    const minWordId = 1;

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
    ''', [minWordId]);

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
    );
  }

  // Get all words that have been seen at least twice
  Future<List<Map<String, dynamic>>> getLastStudiedWords(int count) async {
    final db = await database;

    return await db.rawQuery('''
      WITH LatestProgress AS (
        SELECT 
          word_id,
          box_level,
          timestamp,
          ROW_NUMBER() OVER (PARTITION BY word_id ORDER BY timestamp DESC) as rn,
          COUNT(*) OVER (PARTITION BY word_id) as nb_entries
        FROM user_progress
      )
      SELECT 
        v.*,
        lp.box_level,
        lp.timestamp
      FROM LatestProgress lp
      JOIN vocabulary v ON v.id = lp.word_id
      WHERE lp.rn = 1
        AND lp.nb_entries >= 2
      ORDER BY lp.timestamp DESC
    ''');
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

  // Close the database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<double> getTodayProgress() async {
    final db = await database;

    // Get the start of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Get the number of words learned before today (box_level > 0)
    final wordsBeforeToday = await db.rawQuery('''
      WITH LastProgressBeforeToday AS (
        SELECT box_level, MAX(timestamp) as last_timestamp
        FROM user_progress
        WHERE timestamp < ?
        GROUP BY word_id
      )
      SELECT coalesce(sum(box_level), 0) as learned_words
      FROM LastProgressBeforeToday lp
    ''', [startOfDay.toIso8601String()]);

    // Get the current number of words learned (box_level > 0)
    final wordsNow = await db.rawQuery('''
      WITH LastProgress AS (
        SELECT box_level, MAX(timestamp) as last_timestamp
        FROM user_progress
        GROUP BY word_id
      )
      SELECT sum(box_level)  as learned_words
      FROM LastProgress lp
      
    ''');
    final int startCount = wordsBeforeToday.first['learned_words'] as int;
    final int currentCount = wordsNow.first['learned_words'] as int;

    // Calculate progress (difference in number of words learned)
    return (currentCount - startCount).toDouble() / 5;
  }
}
