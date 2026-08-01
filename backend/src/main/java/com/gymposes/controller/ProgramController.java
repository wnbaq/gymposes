package com.gymposes.controller;

import com.gymposes.dto.CreateProgramRequest;
import com.gymposes.dto.ProgramResponse;
import com.gymposes.service.ProgramService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/programs")
@RequiredArgsConstructor
public class ProgramController {

    private final ProgramService programService;

    @PostMapping
    public ResponseEntity<ProgramResponse> create(
            @RequestBody CreateProgramRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(programService.createProgram(user.getUsername(), request));
    }

    @GetMapping
    public ResponseEntity<List<ProgramResponse>> list(@AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(programService.listPrograms(user.getUsername()));
    }
}
