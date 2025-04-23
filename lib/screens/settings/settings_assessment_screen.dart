// Importations
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/preferences_service.dart';
import '../main_screen.dart';
import 'settings_screen.dart';

class SettingsAssessmentScreen extends StatefulWidget {
  const SettingsAssessmentScreen({super.key});

  @override
  State<SettingsAssessmentScreen> createState() =>
      _SettingsAssessmentScreenState();
}

class _SettingsAssessmentScreenState extends State<SettingsAssessmentScreen> {
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
      default:
        nextLevel = 'C1';
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
        if (_errCount >= 2) {
          // Si l'utilisateur a répondu "Non" une fois ou "Je l'ai déjà vu" deux fois
          _finalLevel = _currentLevel;
          _showConclusionAndFinish();
        } else if (_currentLevel == 'C1') {
          _finalLevel = 'C1';
          _showConclusionAndFinish();
        } else {
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
                  'Évaluation terminée !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'En fonction de vos réponses, nous commencerons par le niveau $_finalLevel.',
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
                      'Commencer l’apprentissage →',
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
              builder: (context) => const SettingsScreen(),
            ),
          ),
        ),
        title: const Text(
          "Découvrons ton niveau",
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
                "Évaluation du niveau $_currentLevel",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
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
                    const Text(
                      'Connaissez-vous ce mot ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentWord['french']!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_showTranslation)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showTranslation = true;
                          });
                        },
                        child: const Text(
                          'Afficher la traduction',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    else
                      Text(
                        currentWord['spanish']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
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
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    _finalLevel = _currentLevel;
                    _showConclusionAndFinish();
                  },
                  child: Text(
                    'Passer l’évaluation →',
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
