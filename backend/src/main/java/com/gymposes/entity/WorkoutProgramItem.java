package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "workout_program_items")
@Data @EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutProgramItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "program_id", nullable = false)
    private WorkoutProgram program;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Column(nullable = false)
    private Integer sets;

    @Column(nullable = false)
    private Integer reps;

    @Column(nullable = false)
    private Integer orderIndex;
}
