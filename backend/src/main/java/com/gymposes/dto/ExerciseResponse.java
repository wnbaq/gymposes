package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class ExerciseResponse {
    private Long id;
    private String name;
    private String description;
    private Integer defaultReps;
    private String lottieAssetPath;
    private Double difficultyScore;
}
