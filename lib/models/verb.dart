class Verb {
  final int verb_id;
  final String verbes;
  final String temps;
  final String traduction;
  final String conjugaison_complete;
  final String conjugaison;
  final String personne;
  final String phrase_es;
  final String phrase_fr;
  final int nb_time_seen;

  Verb({
    required this.verb_id,
    required this.verbes,
    required this.temps,
    required this.traduction,
    required this.conjugaison_complete,
    required this.conjugaison,
    required this.personne,
    required this.phrase_es,
    required this.phrase_fr,
    this.nb_time_seen = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': verb_id,
      'verbes': verbes,
      'temps': temps,
      'traduction': traduction,
      'conjugaison_complete': conjugaison_complete,
      'conjugaison': conjugaison,
      'personne': personne,
      'phrase_es': phrase_es,
      'phrase_fr': phrase_fr,
      'nb_time_seen': nb_time_seen,
    };
  }

  factory Verb.fromMap(Map<String, dynamic> map) {
    return Verb(
      verb_id: map['id'] as int,
      verbes: map['verbes'] as String,
      temps: map['temps'] as String,
      traduction: map['traduction'] as String,
      conjugaison_complete: map['conjugaison_complete'] as String,
      conjugaison: map['conjugaison'] as String,
      personne: map['personne'] as String,
      phrase_es: map['phrase_es'] as String,
      phrase_fr: map['phrase_fr'] as String,
      nb_time_seen: map['nb_time_seen'] as int? ?? 0,
    );
  }

  factory Verb.fromJson(Map<String, dynamic> json) {
    return Verb(
      verb_id: json['id'] as int? ?? 0,
      verbes: json['verbes'] as String? ?? 'ERROR',
      temps: json['temps'] as String? ?? 'ERROR',
      traduction: json['traduction'] as String? ?? '',
      conjugaison_complete: json['conjugaison_complete'] as String? ?? '',
      conjugaison: json['conjugaison'] as String? ?? '',
      personne: json['personne'] as String? ?? '',
      phrase_es: json['phrase_es'] as String? ?? '',
      phrase_fr: json['phrase_fr'] as String? ?? '',
    );
  }
}
