import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import 'onboarding_notification_screen.dart';

class OnboardingDailyGoalScreen extends StatefulWidget {
  const OnboardingDailyGoalScreen({super.key});

  @override
  State<OnboardingDailyGoalScreen> createState() =>
      _OnboardingDailyGoalScreenState();
}

class _OnboardingDailyGoalScreenState extends State<OnboardingDailyGoalScreen> {
  int _selectedGoal = 5;
  final PreferencesService _preferencesService = PreferencesService();

  String _getEstimatedTime(int words) {
    // On estime environ 2 minutes par mot
    final minutes = words;
    final maxMinutes = (minutes * 1.5).round();
    return '$minutes - $maxMinutes minutes par jour';
  }

  @override
  Widget build(BuildContext context) {
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
          'Set Your Daily Goal',
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
              const Text(
                'How many new words would you like to learn each day?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Goal Selection
              _buildGoalOption(3, _getEstimatedTime(3)),
              const SizedBox(height: 16),
              _buildGoalOption(5, _getEstimatedTime(5)),
              const SizedBox(height: 16),
              _buildGoalOption(10, _getEstimatedTime(10)),
              const SizedBox(height: 16),
              _buildGoalOption(15, _getEstimatedTime(15)),
              const Spacer(),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _preferencesService.setDailyWordGoal(_selectedGoal);
                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationOnboardingScreen(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildGoalOption(int goal, String timeEstimate) {
    final bool isSelected = _selectedGoal == goal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$goal mots par jour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  timeEstimate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
