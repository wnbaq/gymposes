package com.gymposes.repository;
import com.gymposes.entity.Exercise;
import com.gymposes.entity.User;
import com.gymposes.entity.UserScore;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface UserScoreRepository extends JpaRepository<UserScore, Long> {
    Optional<UserScore> findByUserAndExercise(User user, Exercise exercise);
    List<UserScore> findByUserAndExerciseIn(User user, List<Exercise> exercises);
}
