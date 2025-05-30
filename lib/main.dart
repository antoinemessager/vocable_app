import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if it's first launch using a new key
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('is_first_launch_v2') ?? true;

  if (isFirstLaunch) {
    // Supprimer la base de données existante lors du premier lancement
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vocable.db');
    await databaseFactory.deleteDatabase(path);
  }

  // Initialize database
  await DatabaseService.instance.database;

  // Mettre is_first_launch à false après l'initialisation de la base de données
  if (isFirstLaunch) {
    await prefs.setBool('is_first_launch_v2', false);
  }

  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocable',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4169E1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        cardTheme: ThemeData.light().cardTheme.copyWith(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4169E1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
        cardTheme: ThemeData.light().cardTheme.copyWith(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
        ),
      ),
      home: isFirstLaunch ? const OnboardingScreen() : const MainScreen(),
    );
  }
}
