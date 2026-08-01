package com.gymposes.dto;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
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
    private MuscleGroup muscleGroup;
    private ExerciseLocation location;

    public static ExerciseResponse from(Exercise e) {
        return ExerciseResponse.builder()
            .id(e.getId()).name(e.getName()).description(e.getDescription())
            .defaultReps(e.getDefaultReps()).lottieAssetPath(e.getLottieAssetPath())
            .difficultyScore(e.getDifficultyScore())
            .muscleGroup(e.getMuscleGroup()).location(e.getLocation())
            .build();
    }
}
