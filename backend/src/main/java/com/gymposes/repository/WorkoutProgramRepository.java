package com.gymposes.repository;
import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutProgramRepository extends JpaRepository<WorkoutProgram, Long> {
    List<WorkoutProgram> findByUser(User user);
}
