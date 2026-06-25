package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutStartResponse {
    private Long sessionId;
    private ExerciseResponse exercise;
    private Integer remainingSeconds;
}
