package com.gymposes.dto;
import lombok.Data;

@Data
public class ProgramItemRequest {
    private Long exerciseId;
    private Integer sets;
    private Integer reps;
    private Integer orderIndex;
}
