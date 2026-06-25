package com.gymposes.service;

import com.gymposes.entity.*;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.WorkoutResult;
import com.gymposes.repository.ExerciseRepository;
import com.gymposes.repository.UserScoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdaptiveService {

    private final ExerciseRepository exerciseRepository;
    private final UserScoreRepository userScoreRepository;

    public Exercise selectNextExercise(WorkoutSession session, Long excludeExerciseId) {
        List<Exercise> candidates = exerciseRepository.findByMuscleGroupAndLocationIn(
            session.getRegion(),
            List.of(session.getLocation(), ExerciseLocation.BOTH)
        );

        Map<Long, Double> userScores = userScoreRepository
            .findByUserAndExerciseIn(session.getUser(), candidates)
            .stream()
            .collect(Collectors.toMap(us -> us.getExercise().getId(), UserScore::getScore));

        double targetScore = session.getTargetScore();

        return candidates.stream()
            .filter(e -> !e.getId().equals(excludeExerciseId))
            .min(Comparator.comparingDouble(e -> {
                double uScore = userScores.getOrDefault(e.getId(), 5.0);
                double effectiveScore = e.getDifficultyScore() * 0.6 + uScore * 0.4;
                return Math.abs(effectiveScore - targetScore);
            }))
            .orElse(candidates.get(0));
    }

    public void updateUserScore(User user, Exercise exercise, WorkoutResult result) {
        UserScore score = userScoreRepository.findByUserAndExercise(user, exercise)
            .orElse(UserScore.builder().user(user).exercise(exercise).score(5.0).build());

        switch (result) {
            case GOOD -> score.setScore(score.getScore() + 1.0);
            case BAD  -> score.setScore(score.getScore() - 0.5);
            case SKIP -> { /* no change */ }
        }
        userScoreRepository.save(score);
    }

    public double updateTargetScore(double current, WorkoutResult result) {
        return switch (result) {
            case GOOD -> current + 0.5;
            case BAD  -> current - 0.3;
            case SKIP -> current;
        };
    }
}
