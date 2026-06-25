package com.gymposes.repository;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {
    List<Exercise> findByMuscleGroupAndLocationIn(MuscleGroup muscleGroup, List<ExerciseLocation> locations);
}
