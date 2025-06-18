import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_pair.dart';
import '../models/word_progress.dart';
import '../models/verb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'word_database_service.dart';
import 'verb_database_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Créer une nouvelle base de données
    _database = await _initDB('vocable.db');

    // Initialiser les services spécialisés avec la base de données
    WordDatabaseService.instance.setDatabase(_database!);
    VerbDatabaseService.instance.setDatabase(_database!);

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment version to force database recreation
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables and recreate them
        await db.execute('DROP TABLE IF EXISTS user_progress_verb');
        await db.execute('DROP TABLE IF EXISTS user_progress');
        await db.execute('DROP TABLE IF EXISTS verb');
        await db.execute('DROP TABLE IF EXISTS vocabulary');
        await _createDB(db, newVersion);
      },
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
        spanish_context TEXT NOT NULL,
        distance REAL NOT NULL DEFAULT 1.0
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
        verbes TEXT NOT NULL,
        temps TEXT NOT NULL,
        traduction TEXT NOT NULL,
        conjugaison_complete TEXT NOT NULL,
        conjugaison TEXT NOT NULL,
        personne TEXT NOT NULL,
        phrase_es TEXT NOT NULL,
        phrase_fr TEXT NOT NULL,
        UNIQUE(verbes, temps, personne)
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
    final List<WordPair> wordPairs =
        await WordDatabaseService.instance.readJsonFromAssets();
    final List<Map<String, dynamic>> verbs =
        await VerbDatabaseService.instance.readVerbsFromAssets();

    final batch = db.batch();

    // Insert vocabulary words
    for (var pair in wordPairs) {
      batch.insert('vocabulary', {
        'id': pair.word_id,
        'french_word': pair.word_fr,
        'spanish_word': pair.word_es,
        'french_context': pair.fr_sentence,
        'spanish_context': pair.es_sentence,
        'distance': pair.distance ?? 1.0,
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
    if (verbs.isNotEmpty) {
      for (var verb in verbs) {
        batch.insert('verb', {
          'verbes': verb['verbes'] as String,
          'temps': verb['temps'] as String,
          'traduction': verb['traduction'] as String,
          'conjugaison_complete': verb['conjugaison_complete'] as String,
          'conjugaison': verb['conjugaison'] as String,
          'personne': verb['personne'] as String,
          'phrase_es': verb['phrase_es'] as String,
          'phrase_fr': verb['phrase_fr'] as String,
        });
      }
    } else {
      print('Aucun verbe chargé depuis le fichier JSON');
    }

    // Commit the batch to insert all data
    await batch.commit(noResult: true);

    // Now that all verbs are inserted, initialize user_progress_verb
    final List<Map<String, dynamic>> insertedVerbs = await db.query('verb');
    if (insertedVerbs.isNotEmpty) {
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
  }

  // Méthodes de délégation pour les mots
  Future<void> recordProgress(int wordId,
      {bool isCorrect = true, bool isTooEasy = false}) async {
    await WordDatabaseService.instance
        .recordProgress(wordId, isCorrect: isCorrect, isTooEasy: isTooEasy);
  }

  Future<WordPair?> getNextWordForReview() async {
    return await WordDatabaseService.instance.getNextWordForReview();
  }

  Future<List<Map<String, dynamic>>> getLastStudiedWords() async {
    return await WordDatabaseService.instance.getLastStudiedWords();
  }

  Future<void> updateWordLevel(int wordId, int newLevel) async {
    await WordDatabaseService.instance.updateWordLevel(wordId, newLevel);
  }

  Future<double> getTodayProgress() async {
    return await WordDatabaseService.instance.getTodayProgress();
  }

  Future<int> getDayStreak() async {
    return await WordDatabaseService.instance.getDayStreak();
  }

  Future<double> getTotalMasteredWords() async {
    return await WordDatabaseService.instance.getTotalMasteredWords();
  }

  Future<Map<String, double>> getCEFRProgress() async {
    return await WordDatabaseService.instance.getCEFRProgress();
  }

  Future<Map<String, List<Map<String, String>>>> getAssessmentWords() async {
    return await WordDatabaseService.instance.getAssessmentWords();
  }

  Future<double> getWordsLearnedBetweenDates(
      DateTime startDate, DateTime endDate) async {
    return await WordDatabaseService.instance
        .getWordsLearnedBetweenDates(startDate, endDate);
  }

  Future<List<Map<String, dynamic>>> getWordsForCEFRLevel(String level) async {
    return await WordDatabaseService.instance.getWordsForCEFRLevel(level);
  }

  // Méthodes de délégation pour les verbes
  Future<Verb> getRandomVerb() async {
    return await VerbDatabaseService.instance.getRandomVerb();
  }

  Future<double> getVerbProgress() async {
    return await VerbDatabaseService.instance.getVerbProgress();
  }

  Future<void> recordVerbProgress(int verbId,
      {bool isCorrect = true, bool isTooEasy = false}) async {
    await VerbDatabaseService.instance
        .recordVerbProgress(verbId, isCorrect: isCorrect, isTooEasy: isTooEasy);
  }

  Future<int> getVerbBoxLevel(int verbId) async {
    return await VerbDatabaseService.instance.getVerbBoxLevel(verbId);
  }

  Future<double> getTotalMasteredVerbs() async {
    return await VerbDatabaseService.instance.getTotalMasteredVerbs();
  }

  Future<int> getVerbDayStreak() async {
    return await VerbDatabaseService.instance.getVerbDayStreak();
  }

  Future<double> getVerbProgressBetweenDates(
      DateTime startDate, DateTime endDate) async {
    return await VerbDatabaseService.instance
        .getVerbProgressBetweenDates(startDate, endDate);
  }

  Future<Map<String, Map<String, int>>> getTenseProgress() async {
    return await VerbDatabaseService.instance.getTenseProgress();
  }

  Future<int> insertVerb(Verb verb) async {
    return await VerbDatabaseService.instance.insertVerb(verb);
  }

  Future<void> insertVerbs(List<Map<String, dynamic>> verbs) async {
    await VerbDatabaseService.instance.insertVerbs(verbs);
  }

  Future<Verb> getFirstVerb() async {
    return await VerbDatabaseService.instance.getFirstVerb();
  }
}
