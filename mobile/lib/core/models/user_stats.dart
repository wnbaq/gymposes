class UserStats {
  final int totalSessions;
  final Map<String, int> regionBreakdown;

  const UserStats({required this.totalSessions, required this.regionBreakdown});

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalSessions: json['totalSessions'] as int,
    regionBreakdown: Map<String, int>.from(
      (json['regionBreakdown'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
    ),
  );
}
