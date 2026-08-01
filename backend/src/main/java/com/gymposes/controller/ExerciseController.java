package com.gymposes.controller;

import com.gymposes.dto.ExerciseResponse;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import com.gymposes.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseRepository exerciseRepository;

    @GetMapping
    public ResponseEntity<List<ExerciseResponse>> list(
            @RequestParam(required = false) ExerciseLocation location,
            @RequestParam(required = false) MuscleGroup muscleGroup) {
        List<Exercise> exercises = exerciseRepository.findAll().stream()
            .filter(e -> location == null || e.getLocation() == location || e.getLocation() == ExerciseLocation.BOTH)
            .filter(e -> muscleGroup == null || e.getMuscleGroup() == muscleGroup)
            .toList();
        return ResponseEntity.ok(exercises.stream().map(ExerciseResponse::from).toList());
    }
}
