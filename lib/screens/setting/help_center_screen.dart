import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'How Vocable Works',
            'Vocable is a language learning app that uses a spaced repetition system to help you learn French and Spanish vocabulary effectively. Here\'s how it works:',
            [
              '1. Daily Learning Goal',
              'Set your daily word goal in the Settings tab. This determines how many new words you\'ll learn each day. The app will track your progress and show you how close you are to reaching your goal.',
              '2. Learning Process',
              'When you start learning, you\'ll see a French word. Try to recall its Spanish translation. If you can\'t remember, tap "Reveal Translation" to see the answer.',
              '3. Review System',
              'After seeing the translation, you have three options:\n'
                  '• Correct: You knew the word\n'
                  '• Incorrect: You didn\'t know the word\n'
                  '• Too Easy: The word is too simple for you\n'
                  'The app uses your responses to determine when to show you the word again.',
              '4. Progress Tracking',
              'Your progress is tracked in several ways:\n'
                  '• Daily progress bar shows your completion towards your goal\n'
                  '• History tab shows your learning history\n'
                  '• Mastered words are marked with a star\n'
                  '• Your streak shows how many consecutive days you\'ve been learning',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Tips for Effective Learning',
            'To get the most out of Vocable, follow these tips:',
            [
              '1. Be Consistent',
              'Try to learn every day, even if it\'s just a few words. Consistency is key to language learning.',
              '2. Be Honest',
              'When reviewing words, be honest about whether you knew them or not. This helps the app show you words at the right time.',
              '3. Use Context',
              'Pay attention to example sentences when available. They help you understand how words are used in real situations.',
              '4. Set Realistic Goals',
              'Start with a manageable daily goal and increase it gradually as you get comfortable.',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Understanding the Interface',
            'The app has three main sections:',
            [
              '1. Home Tab',
              '• Shows your current word to learn\n'
                  '• Displays your daily progress\n'
                  '• Shows your mastered words count\n'
                  '• Tracks your learning streak',
              '2. History Tab',
              '• Shows your learning history\n'
                  '• Allows you to review past words\n'
                  '• Lets you adjust word difficulty levels\n'
                  '• Displays your learning statistics',
              '3. Settings Tab',
              '• Set your daily word goal\n'
                  '• Adjust learning preferences\n'
                  '• View app information\n'
                  '• Access help center',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<String> points,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                point,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
      ],
    );
  }
}
