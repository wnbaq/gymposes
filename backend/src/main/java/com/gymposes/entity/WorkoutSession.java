package com.gymposes.entity;

import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "workout_sessions")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    private ExerciseLocation location;

    private Integer durationMinutes;

    @Enumerated(EnumType.STRING)
    private MuscleGroup region;

    @Builder.Default
    private Double targetScore = 5.0;

    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
}
