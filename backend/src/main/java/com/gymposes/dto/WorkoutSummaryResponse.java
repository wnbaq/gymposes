package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutSummaryResponse {
    private Long sessionId;
    private Integer totalExercises;
    private Integer goodCount;
    private Integer badCount;
    private Integer skipCount;
    private Integer durationMinutes;
}
