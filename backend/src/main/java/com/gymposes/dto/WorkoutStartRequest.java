package com.gymposes.dto;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import lombok.Data;

@Data
public class WorkoutStartRequest {
    private ExerciseLocation location;
    private Integer durationMinutes;
    private MuscleGroup region;
}
