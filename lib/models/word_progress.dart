class WordProgress {
  final int wordId;
  final int boxLevel;
  final DateTime timestamp;

  WordProgress({
    required this.wordId,
    required this.boxLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'word_id': wordId,
      'box_level': boxLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WordProgress.fromMap(Map<String, dynamic> map) {
    return WordProgress(
      wordId: map['word_id'] as int,
      boxLevel: map['box_level'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
