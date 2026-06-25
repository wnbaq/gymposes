package com.gymposes.entity;

import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "exercises")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Exercise {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    @Enumerated(EnumType.STRING)
    private MuscleGroup muscleGroup;

    @Enumerated(EnumType.STRING)
    private ExerciseLocation location;

    private Double difficultyScore;
    private Integer defaultReps;
    private String lottieAssetPath;
}
