package com.gymposes.service;

import com.gymposes.dto.*;
import com.gymposes.entity.*;
import com.gymposes.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ProgramService {

    private final WorkoutProgramRepository programRepository;
    private final WorkoutProgramItemRepository programItemRepository;
    private final ExerciseRepository exerciseRepository;
    private final UserRepository userRepository;

    public ProgramResponse createProgram(String userEmail, CreateProgramRequest request) {
        if (request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Program name is required");
        }
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new IllegalArgumentException("Program must have at least one exercise");
        }

        User user = userRepository.findByEmail(userEmail).orElseThrow();
        WorkoutProgram program = programRepository.save(
            WorkoutProgram.builder().user(user).name(request.getName()).build());

        List<WorkoutProgramItem> items = request.getItems().stream()
            .map(i -> WorkoutProgramItem.builder()
                .program(program)
                .exercise(exerciseRepository.findById(i.getExerciseId())
                    .orElseThrow(() -> new IllegalArgumentException("Unknown exercise: " + i.getExerciseId())))
                .sets(i.getSets())
                .reps(i.getReps())
                .orderIndex(i.getOrderIndex())
                .build())
            .toList();
        programItemRepository.saveAll(items);

        return toResponse(program, items);
    }

    public List<ProgramResponse> listPrograms(String userEmail) {
        User user = userRepository.findByEmail(userEmail).orElseThrow();
        return programRepository.findByUser(user).stream()
            .map(p -> toResponse(p, programItemRepository.findByProgramOrderByOrderIndex(p)))
            .toList();
    }

    private ProgramResponse toResponse(WorkoutProgram program, List<WorkoutProgramItem> items) {
        return ProgramResponse.builder()
            .id(program.getId())
            .name(program.getName())
            .items(items.stream().map(i -> ProgramItemResponse.builder()
                .exerciseId(i.getExercise().getId())
                .sets(i.getSets())
                .reps(i.getReps())
                .orderIndex(i.getOrderIndex())
                .build()).toList())
            .build();
    }
}
