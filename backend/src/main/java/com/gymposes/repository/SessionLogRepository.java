package com.gymposes.repository;
import com.gymposes.entity.SessionLog;
import com.gymposes.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SessionLogRepository extends JpaRepository<SessionLog, Long> {
    List<SessionLog> findBySession(WorkoutSession session);
}
