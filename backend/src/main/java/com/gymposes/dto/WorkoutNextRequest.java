package com.gymposes.dto;
import com.gymposes.enums.WorkoutResult;
import lombok.Data;

@Data
public class WorkoutNextRequest {
    private Long exerciseId;
    private WorkoutResult result;
}
