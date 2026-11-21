class SquadMissionProgress {
  const SquadMissionProgress({
    required this.key,
    required this.title,
    required this.target,
    required this.progress,
    required this.reward,
    required this.claimed,
  });

  final String key;
  final String title;
  final int target;
  final int progress;
  final int reward;
  final bool claimed;

  double get ratio {
    if (target <= 0) return 0;
    return (progress / target).clamp(0, 1);
  }

  bool get isCompleted => progress >= target;

  SquadMissionProgress copyWith({
    String? key,
    String? title,
    int? target,
    int? progress,
    int? reward,
    bool? claimed,
  }) {
    return SquadMissionProgress(
      key: key ?? this.key,
      title: title ?? this.title,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      reward: reward ?? this.reward,
      claimed: claimed ?? this.claimed,
    );
  }
}

class SquadWeeklyProgress {
  const SquadWeeklyProgress({
    required this.squadKey,
    required this.weekId,
    required this.currentStreak,
    required this.bestStreak,
    required this.missions,
  });

  final String squadKey;
  final String weekId;
  final int currentStreak;
  final int bestStreak;
  final List<SquadMissionProgress> missions;

  static SquadWeeklyProgress fromMap(Map<String, dynamic> map) {
    final missionDefs = (map['missions'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
    final missionList = <SquadMissionProgress>[];

    for (final entry in missionDefs.entries) {
      final raw = entry.value;
      missionList.add(
        SquadMissionProgress(
          key: entry.key,
          title: (raw['title'] ?? entry.key).toString(),
          target: (raw['target'] as num? ?? 0).toInt(),
          progress: (raw['progress'] as num? ?? 0).toInt(),
          reward: (raw['reward'] as num? ?? 0).toInt(),
          claimed: raw['claimed'] == true,
        ),
      );
    }

    missionList.sort((a, b) => a.key.compareTo(b.key));

    return SquadWeeklyProgress(
      squadKey: (map['squad_key'] ?? '').toString(),
      weekId: (map['week_id'] ?? '').toString(),
      currentStreak: (map['streak_current'] as num? ?? 0).toInt(),
      bestStreak: (map['streak_best'] as num? ?? 0).toInt(),
      missions: missionList,
    );
  }
}
