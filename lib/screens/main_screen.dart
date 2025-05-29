import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'word_screen.dart';
import 'verb_screen.dart';
import 'settings/settings_screen.dart';
import 'progress/progress_screen.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static _MainScreenState? _state;

  static void updateProgress() {
    _state?._loadProgress();
  }

  @override
  State<MainScreen> createState() {
    _state = _MainScreenState();
    return _state!;
  }
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  double _wordProgress = 0.0;
  double _verbProgress = 0.0;
  int _wordGoal = 5;
  int _verbGoal = 2;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (_pageController.page?.round() == _currentIndex) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final wordGoal = prefs.getInt('daily_word_goal') ?? 5;
    final verbGoal = prefs.getInt('daily_verb_goal') ?? 2;

    final wordProgress = await DatabaseService.instance.getTodayProgress();
    final verbProgress = await DatabaseService.instance.getVerbProgress();

    if (mounted) {
      setState(() {
        _wordProgress = wordProgress;
        _verbProgress = verbProgress;
        _wordGoal = wordGoal;
        _verbGoal = verbGoal;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _loadProgress();
        },
        children: [
          HomeScreen(
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _pageController.jumpToPage(index);
              _loadProgress();
            },
          ),
          const WordScreen(),
          const VerbScreen(),
          const ProgressScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[200],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
          _loadProgress();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black87,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontSize: 10, height: 2),
        unselectedLabelStyle: const TextStyle(fontSize: 10, height: 2),
        items: [
          BottomNavigationBarItem(
            icon: Container(height: 44, child: Icon(Icons.home_outlined)),
            activeIcon: Container(height: 44, child: Icon(Icons.home)),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Container(
              height: 44,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined),
                    if (_wordProgress < _wordGoal)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            activeIcon: Container(
              height: 44,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.menu_book, color: Colors.blue),
                    if (_wordProgress < _wordGoal)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            label: 'Vocabulaire',
          ),
          BottomNavigationBarItem(
            icon: Container(
              height: 44,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.edit_note_outlined),
                    if (_verbProgress < _verbGoal)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            activeIcon: Container(
              height: 44,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.edit_note, color: Colors.blue),
                    if (_verbProgress < _verbGoal)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            label: 'Conjugaison',
          ),
          BottomNavigationBarItem(
            icon: Container(height: 44, child: Icon(Icons.bar_chart_outlined)),
            activeIcon: Container(height: 44, child: Icon(Icons.bar_chart)),
            label: 'Progression',
          ),
          BottomNavigationBarItem(
            icon: Container(height: 44, child: Icon(Icons.settings_outlined)),
            activeIcon: Container(height: 44, child: Icon(Icons.settings)),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
