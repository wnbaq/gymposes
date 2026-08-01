package com.gymposes.repository;
import com.gymposes.entity.WorkoutProgram;
import com.gymposes.entity.WorkoutProgramItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutProgramItemRepository extends JpaRepository<WorkoutProgramItem, Long> {
    List<WorkoutProgramItem> findByProgramOrderByOrderIndex(WorkoutProgram program);
}
