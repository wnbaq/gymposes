package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data @Builder
public class ProgramResponse {
    private Long id;
    private String name;
    private List<ProgramItemResponse> items;
}
