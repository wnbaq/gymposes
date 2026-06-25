package com.gymposes.entity;

import com.gymposes.enums.WorkoutResult;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "session_logs")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SessionLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "session_id", nullable = false)
    private WorkoutSession session;

    @ManyToOne @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Enumerated(EnumType.STRING)
    private WorkoutResult result;

    private LocalDateTime timestamp;
}
