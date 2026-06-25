package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_scores",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "exercise_id"}))
@Data @EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor @AllArgsConstructor @Builder
public class UserScore {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Builder.Default
    private Double score = 5.0;
}
