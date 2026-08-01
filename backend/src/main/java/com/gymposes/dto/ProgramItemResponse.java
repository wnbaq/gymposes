package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class ProgramItemResponse {
    private Long exerciseId;
    private Integer sets;
    private Integer reps;
    private Integer orderIndex;
}
