class Exercise {
  final int id;
  final String name;
  final String description;
  final int defaultReps;
  final String lottieAssetPath;
  final double difficultyScore;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultReps,
    required this.lottieAssetPath,
    required this.difficultyScore,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as int,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    defaultReps: (json['defaultReps'] as int?) ?? 12,
    lottieAssetPath: (json['lottieAssetPath'] as String?) ?? 'placeholder.json',
    difficultyScore: (json['difficultyScore'] as num?)?.toDouble() ?? 5.0,
  );
}
