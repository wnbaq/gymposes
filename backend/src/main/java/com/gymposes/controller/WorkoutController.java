package com.gymposes.controller;

import com.gymposes.dto.*;
import com.gymposes.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/workout")
@RequiredArgsConstructor
public class WorkoutController {

    private final WorkoutService workoutService;

    @PostMapping("/start")
    public ResponseEntity<WorkoutStartResponse> start(
            @RequestBody WorkoutStartRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(workoutService.startSession(user.getUsername(), request));
    }

    @PostMapping("/{sessionId}/next")
    public ResponseEntity<WorkoutNextResponse> next(
            @PathVariable Long sessionId,
            @RequestBody WorkoutNextRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(workoutService.nextExercise(user.getUsername(), sessionId, request));
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<WorkoutSummaryResponse> complete(@PathVariable Long sessionId) {
        return ResponseEntity.ok(workoutService.completeSession(sessionId));
    }
}
