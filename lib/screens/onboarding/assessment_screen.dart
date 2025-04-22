import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../main_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentWordIndex = 0;
  bool _showTranslation = false;
  String _currentLevel = 'A1';
  int _seenCount = 0;
  bool _showingConclusion = false;
  String _finalLevel = 'A1';
  bool _hasAnsweredNo = false;

  final Map<String, List<Map<String, String>>> _wordsByLevel = {
    'A1': [
      {'french': 'aussi', 'spanish': 'también', 'rank': '53'},
      {'french': 'jour', 'spanish': 'día', 'rank': '71'},
      {'french': 'mettre', 'spanish': 'poner', 'rank': '77'},
      {'french': 'rester', 'spanish': 'quedar', 'rank': '89'},
      {'french': 'porter', 'spanish': 'llevar', 'rank': '93'},
      {'french': 'rien', 'spanish': 'nada', 'rank': '95'},
      {'french': 'appeler', 'spanish': 'llamar', 'rank': '104'},
      {'french': 'prendre', 'spanish': 'tomar', 'rank': '122'},
      {'french': 'femme', 'spanish': 'mujer', 'rank': '127'},
      {'french': 'ensuite', 'spanish': 'luego', 'rank': '132'},
    ],
    'A2': [
      {'french': 'face à', 'spanish': 'frente', 'rank': '260'},
      {'french': 'entendre', 'spanish': 'oír', 'rank': '263'},
      {'french': 'dont', 'spanish': 'cuyo', 'rank': '264'},
      {'french': 'terminer', 'spanish': 'acabar', 'rank': '266'},
      {'french': 'aussi', 'spanish': 'tampoco', 'rank': '279'},
      {'french': 'encore', 'spanish': 'aún', 'rank': '282'},
      {'french': 'sujet', 'spanish': 'tema', 'rank': '283'},
      {'french': 'argent', 'spanish': 'dinero', 'rank': '291'},
      {'french': 'même', 'spanish': 'incluso', 'rank': '294'},
      {'french': 'domaine', 'spanish': 'campo', 'rank': '295'},
    ],
    'B1': [
      {'french': 'objectif', 'spanish': 'propósito', 'rank': '752'},
      {'french': 'attention', 'spanish': 'cuidado', 'rank': '754'},
      {'french': 'niveau', 'spanish': 'grado', 'rank': '756'},
      {'french': 'vaste', 'spanish': 'amplio', 'rank': '763'},
      {'french': 'répondre', 'spanish': 'contestar', 'rank': '764'},
      {'french': 'journal', 'spanish': 'periódico', 'rank': '765'},
      {'french': 'inquiéter', 'spanish': 'preocupar', 'rank': '766'},
      {'french': 'tableau', 'spanish': 'cuadro', 'rank': '779'},
      {'french': 'poste', 'spanish': 'cargo', 'rank': '791'},
      {'french': 'étage', 'spanish': 'piso', 'rank': '797'},
    ],
    'B2': [
      {'french': 'forêt', 'spanish': 'bosque', 'rank': '1506'},
      {'french': 'brûler', 'spanish': 'quemar', 'rank': '1509'},
      {'french': 'appel', 'spanish': 'llamado', 'rank': '1510'},
      {'french': 'attente', 'spanish': 'espera', 'rank': '1525'},
      {'french': 'dépenser', 'spanish': 'gastar', 'rank': '1526'},
      {'french': 'offrir', 'spanish': 'regalar', 'rank': '1528'},
      {'french': 'plaindre', 'spanish': 'quejar', 'rank': '1530'},
      {'french': 'nettoyer', 'spanish': 'limpiar', 'rank': '1537'},
      {'french': 'rapport', 'spanish': 'informe', 'rank': '1548'},
      {'french': 'puissant', 'spanish': 'poderoso', 'rank': '1560'},
    ],
    'C1': [
      {'french': 'récolte', 'spanish': 'cosecha', 'rank': '2780'},
      {'french': 'mou', 'spanish': 'blando', 'rank': '2785'},
      {'french': 'maître', 'spanish': 'amo', 'rank': '2789'},
      {'french': 'engagée', 'spanish': 'comprometido', 'rank': '2805'},
      {'french': 'ennuyeux', 'spanish': 'aburrido', 'rank': '2815'},
      {'french': 'boisson', 'spanish': 'bebida', 'rank': '2830'},
      {'french': 'discussion', 'spanish': 'charla', 'rank': '2832'},
      {'french': 'pomme', 'spanish': 'manzana', 'rank': '2855'},
      {'french': 'morceau', 'spanish': 'pedazo', 'rank': '2857'},
      {'french': 'épuisé', 'spanish': 'agotado', 'rank': '2863'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _hasAnsweredNo = false;
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
      _seenCount = 0;
      _currentLevel = nextLevel;
    });
  }

  void _showConclusionAndFinish() {
    setState(() {
      _showingConclusion = true;
    });
  }

  void _handleAnswer(bool knows) {
    if (!knows) {
      _seenCount++;
    }

    setState(() {
      if (_currentWordIndex < _wordsByLevel[_currentLevel]!.length - 1) {
        _currentWordIndex++;
        _showTranslation = false;
      } else {
        // L'utilisateur a terminé les 10 mots de ce niveau
        if (_seenCount >= 2 || _hasAnsweredNo) {
          // Si l'utilisateur a répondu "I've seen it before" deux fois ou "No" une fois
          _finalLevel = _currentLevel;
          _showConclusionAndFinish();
        } else if (_currentLevel == 'C1') {
          // Si l'utilisateur a réussi le niveau C1
          _finalLevel = 'C1';
          _showConclusionAndFinish();
        } else {
          // Sinon, on passe au niveau suivant
          _moveToNextLevel();
          _showTranslation = false;
        }
      }
    });
  }

  void _handleSeenAnswer() {
    _seenCount++;
    _handleAnswer(false);
  }

  void _handleNoAnswer() {
    _hasAnsweredNo = true;
    _handleAnswer(false);
  }

  @override
  Widget build(BuildContext context) {
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
                  'Assessment Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Based on your responses, we will start with level $_finalLevel vocabulary.',
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Learning →',
                      style: TextStyle(fontSize: 16),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Let's find your level",
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
                "Testing level $_currentLevel",
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
                'Word ${_currentWordIndex + 1} of $totalWordsInLevel',
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
                    const Text(
                      'Do you know this word?',
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
                          'Show translation',
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
              // Answer Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Yes, I know this word well',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSeenAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                        foregroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "I've seen it before",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleNoAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.red[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "No, I don't know this word",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Skip Button
              Center(
                child: TextButton(
                  onPressed: () {
                    _finalLevel = _currentLevel;
                    _showConclusionAndFinish();
                  },
                  child: Text(
                    'Skip assessment →',
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
