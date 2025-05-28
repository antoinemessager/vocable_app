import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'verb_screen.dart';
import 'settings/settings_screen.dart';
import 'progress_screen.dart';
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
        children: const [
          HomeScreen(),
          VerbScreen(),
          ProgressScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.grey[200],
        surfaceTintColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
          _loadProgress();
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.blue[100],
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        destinations: [
          NavigationDestination(
            icon: Stack(
              children: [
                Icon(Icons.menu_book_outlined, color: Colors.black87),
                if (_wordProgress < _wordGoal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Stack(
              children: [
                Icon(Icons.menu_book, color: Colors.black87),
                if (_wordProgress < _wordGoal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Vocabulaire',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                Icon(Icons.edit_note_outlined, color: Colors.black87),
                if (_verbProgress < _verbGoal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Stack(
              children: [
                Icon(Icons.edit_note, color: Colors.black87),
                if (_verbProgress < _verbGoal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Conjugaison',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.black87),
            label: 'Progression',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.settings, color: Colors.black87),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
