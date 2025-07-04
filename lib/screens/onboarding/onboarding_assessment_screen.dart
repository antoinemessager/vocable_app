import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';
import '../main_screen.dart';
import 'onboarding_notification_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentWordIndex = 0;
  bool _showTranslation = false;
  String _currentLevel = 'A1';
  int _errCount = 0;
  bool _showingConclusion = false;
  String _finalLevel = 'A1';
  Map<String, List<Map<String, String>>> _wordsByLevel = {};

  @override
  void initState() {
    super.initState();
    _loadAssessmentWords();
  }

  Future<void> _loadAssessmentWords() async {
    final words = await DatabaseService.instance.getAssessmentWords();
    setState(() {
      _wordsByLevel = words;
    });
  }

  void _moveToNextLevel() {
    String nextLevel;
    switch (_currentLevel) {
      case 'A1':
        nextLevel = 'A2';
        break;
      case 'A2':
        nextLevel = 'B1';
        break;
      case 'B1':
        nextLevel = 'B2';
        break;
      case 'B2':
        nextLevel = 'C1';
        break;
      case 'C1':
        nextLevel = 'C2';
        break;
      default:
        nextLevel = 'C2';
    }

    setState(() {
      _currentWordIndex = 0;
      _errCount = 0;
      _currentLevel = nextLevel;
    });
  }

  void _showConclusionAndFinish() async {
    // Sauvegarder le niveau de départ
    await PreferencesService().setStartingLevel(_finalLevel);

    // Initialiser les temps verbaux
    await PreferencesService().initializeVerbTenses();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    setState(() {
      _showingConclusion = true;
    });
  }

  void _handleAnswer(int errCount) {
    _errCount = _errCount + errCount;

    setState(() {
      if (_currentWordIndex < _wordsByLevel[_currentLevel]!.length - 1) {
        _currentWordIndex++;
        _showTranslation = false;
      } else {
        // L'utilisateur a terminé les 10 mots de ce niveau
        if (_errCount >= 4) {
          // Si l'utilisateur a répondu "No" une fois ou "I've seen it before" deux fois
          _finalLevel = _currentLevel;
          _showConclusionAndFinish();
        } else if (_currentLevel == 'C1') {
          // Si on est à C1 et que l'utilisateur a bien réussi, on passe à C2
          _finalLevel = 'C2';
          _showConclusionAndFinish();
        } else {
          // Pour les autres niveaux, on continue normalement

          _moveToNextLevel();
          _showTranslation = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_wordsByLevel.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showingConclusion) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Évaluation Terminée',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Basé sur tes réponses, nous commencerons avec le vocabulaire de niveau $_finalLevel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commencer l\'apprentissage →',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Vérifier si le niveau actuel existe dans _wordsByLevel
    if (!_wordsByLevel.containsKey(_currentLevel) ||
        _wordsByLevel[_currentLevel] == null ||
        _wordsByLevel[_currentLevel]!.isEmpty) {
      // Si le niveau n'existe pas ou est vide, passer au niveau suivant
      _moveToNextLevel();
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentWord = _wordsByLevel[_currentLevel]![_currentWordIndex];
    final totalWordsInLevel = _wordsByLevel[_currentLevel]!.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const NotificationOnboardingScreen(),
            ),
          ),
        ),
        title: const Text(
          "Déterminons ton niveau",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Test du niveau $_currentLevel",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentWordIndex + 1) / totalWordsInLevel,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Mot ${_currentWordIndex + 1} sur $totalWordsInLevel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Word Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      currentWord['french']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_showTranslation)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showTranslation = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Afficher la traduction',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        currentWord['spanish']!,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              if (_showTranslation) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Oui, je connais bien ce mot',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                      foregroundColor: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Je l'ai déjà vu",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Non, je ne connais pas ce mot",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Skip Button
              Center(
                child: TextButton(
                  onPressed: () {
                    _finalLevel = _currentLevel;
                    _showConclusionAndFinish();
                  },
                  child: Text(
                    'Passer l\'évaluation →',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
