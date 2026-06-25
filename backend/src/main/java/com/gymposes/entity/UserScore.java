package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_scores",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "exercise_id"}))
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UserScore {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Builder.Default
    private Double score = 5.0;
}
