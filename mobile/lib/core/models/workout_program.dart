class ProgramItem {
  final int exerciseId;
  final int sets;
  final int reps;
  final int orderIndex;

  const ProgramItem({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.orderIndex,
  });

  factory ProgramItem.fromJson(Map<String, dynamic> json) => ProgramItem(
    exerciseId: json['exerciseId'] as int,
    sets: json['sets'] as int,
    reps: json['reps'] as int,
    orderIndex: json['orderIndex'] as int,
  );
}

class WorkoutProgram {
  final int id;
  final String name;
  final List<ProgramItem> items;

  const WorkoutProgram({required this.id, required this.name, required this.items});

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
    id: json['id'] as int,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>)
        .map((i) => ProgramItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}
