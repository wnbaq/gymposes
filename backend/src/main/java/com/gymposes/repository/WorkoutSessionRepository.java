package com.gymposes.repository;
import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {
    List<WorkoutSession> findByUserOrderByStartedAtDesc(User user);
    List<WorkoutSession> findByUser(User user);
}
