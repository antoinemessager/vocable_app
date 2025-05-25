class Verb {
  final int verb_id;
  final String verb;
  final String tense;
  final String conjugation;
  final int nb_time_seen;

  Verb({
    required this.verb_id,
    required this.verb,
    required this.tense,
    required this.conjugation,
    this.nb_time_seen = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': verb_id,
      'verb': verb,
      'tense': tense,
      'conjugation': conjugation,
      'nb_time_seen': nb_time_seen,
    };
  }

  factory Verb.fromMap(Map<String, dynamic> map) {
    return Verb(
      verb_id: map['id'] as int,
      verb: map['verb'] as String,
      tense: map['tense'] as String,
      conjugation: map['conjugation'] as String,
      nb_time_seen: map['nb_time_seen'] as int? ?? 0,
    );
  }

  factory Verb.fromJson(Map<String, dynamic> json) {
    return Verb(
      verb_id: json['id'] as int? ?? 0,
      verb: json['verb'] as String? ?? 'ERROR',
      tense: json['tense'] as String? ?? 'ERROR',
      conjugation: json['conjugation'] as String? ?? '',
    );
  }
}
