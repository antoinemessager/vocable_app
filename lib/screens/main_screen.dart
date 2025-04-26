import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings/settings_screen.dart';
import 'progress_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          HomeScreen(),
          HistoryScreen(),
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
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.blue[100],
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.home, color: Colors.black87),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.history, color: Colors.black87),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.black87),
            label: 'Progression',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.black87),
            selectedIcon: Icon(Icons.settings, color: Colors.black87),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
