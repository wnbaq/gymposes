import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutSetup {
  final String? location;
  final int? durationMinutes;
  final String? region;

  const WorkoutSetup({this.location, this.durationMinutes, this.region});

  WorkoutSetup copyWith({String? location, int? durationMinutes, String? region}) =>
      WorkoutSetup(
        location: location ?? this.location,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        region: region ?? this.region,
      );

  bool get isComplete =>
      location != null && durationMinutes != null && region != null;
}

final workoutSetupProvider =
    StateNotifierProvider<WorkoutSetupNotifier, WorkoutSetup>((ref) {
  return WorkoutSetupNotifier();
});

class WorkoutSetupNotifier extends StateNotifier<WorkoutSetup> {
  WorkoutSetupNotifier() : super(const WorkoutSetup());

  void setLocation(String loc) => state = state.copyWith(location: loc);
  void setDuration(int mins) => state = state.copyWith(durationMinutes: mins);
  void setRegion(String reg) => state = state.copyWith(region: reg);
  void reset() => state = const WorkoutSetup();
}
