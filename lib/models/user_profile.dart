class UserProfile {
  final String id;
  String name;
  int dailyWordTarget;
  int currentStreak;
  int wordsMastered;
  DateTime lastActivity;
  int proficiencyLevel; // 0: Beginner, 1: Intermediate, 2: Advanced

  UserProfile({
    required this.id,
    required this.name,
    this.dailyWordTarget = 10,
    this.currentStreak = 0,
    this.wordsMastered = 0,
    DateTime? lastActivity,
    this.proficiencyLevel = 0,
  }) : lastActivity = lastActivity ?? DateTime.now();

  // Check if the streak is still valid
  bool isStreakValid() {
    final now = DateTime.now();
    final lastDate = DateTime(
      lastActivity.year,
      lastActivity.month,
      lastActivity.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(lastDate).inDays <= 1;
  }

  // Update streak based on activity
  void updateStreak() {
    final now = DateTime.now();
    if (!isStreakValid()) {
      currentStreak = 0;
    }
    lastActivity = now;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dailyWordTarget': dailyWordTarget,
    'currentStreak': currentStreak,
    'wordsMastered': wordsMastered,
    'lastActivity': lastActivity.toIso8601String(),
    'proficiencyLevel': proficiencyLevel,
  };

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    dailyWordTarget: json['dailyWordTarget'],
    currentStreak: json['currentStreak'],
    wordsMastered: json['wordsMastered'],
    lastActivity: DateTime.parse(json['lastActivity']),
    proficiencyLevel: json['proficiencyLevel'],
  );
}
