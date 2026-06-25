package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutNextResponse {
    private ExerciseResponse exercise;
    private boolean completed;
}
