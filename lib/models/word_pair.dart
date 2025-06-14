class WordPair {
  final int word_id;
  final String word_es;
  final String word_fr;
  final String es_sentence;
  final String fr_sentence;
  final int nb_time_seen;
  final double distance;

  WordPair({
    required this.word_id,
    required this.word_es,
    required this.word_fr,
    required this.es_sentence,
    required this.fr_sentence,
    this.nb_time_seen = 0,
    this.distance = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': word_id,
      'french_word': word_fr,
      'spanish_word': word_es,
      'french_context': fr_sentence,
      'spanish_context': es_sentence,
      'nb_time_seen': nb_time_seen,
      'distance': distance,
    };
  }

  factory WordPair.fromJson(String key, Map<String, dynamic> json) {
    return WordPair(
      word_id: int.tryParse(json['rank'].toString()) ?? 0,
      word_es: json['es_word'] ?? 'ERROR',
      word_fr: json['fr_word'] ?? 'ERROR',
      es_sentence: json['es_sentence'] ?? '',
      fr_sentence: json['fr_sentence'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
