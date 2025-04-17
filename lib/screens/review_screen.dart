import 'package:flutter/material.dart';
import '../models/word_pair.dart';
import '../services/database_service.dart';
import '../widgets/word_card.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  WordPair? _currentWord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  Future<void> _loadNextWord() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final nextWord = await DatabaseService.instance.getNextWordForReview();

      setState(() {
        _currentWord = nextWord;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading next word: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWord == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No words to review right now',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNextWord,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return WordCard(
      word: _currentWord!,
      onAnswer: (wasCorrect) async {
        await DatabaseService.instance.recordProgress(
          _currentWord!.word_id,
          isCorrect: wasCorrect,
        );
        _loadNextWord();
      },
      onTooEasy: () async {
        await DatabaseService.instance.recordProgress(
          _currentWord!.word_id,
          isTooEasy: true,
        );
        _loadNextWord();
      },
    );
  }
}
