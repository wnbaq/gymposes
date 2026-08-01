package com.gymposes.dto;
import lombok.Data;
import java.util.List;

@Data
public class CreateProgramRequest {
    private String name;
    private List<ProgramItemRequest> items;
}
