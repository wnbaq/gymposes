package com.gymposes.controller;

import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutSession;
import com.gymposes.repository.UserRepository;
import com.gymposes.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final WorkoutSessionRepository sessionRepository;
    private final UserRepository userRepository;

    @GetMapping("/history")
    public ResponseEntity<List<WorkoutSession>> history(@AuthenticationPrincipal UserDetails ud) {
        User user = userRepository.findByEmail(ud.getUsername()).orElseThrow();
        return ResponseEntity.ok(sessionRepository.findByUserOrderByStartedAtDesc(user));
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> stats(@AuthenticationPrincipal UserDetails ud) {
        User user = userRepository.findByEmail(ud.getUsername()).orElseThrow();
        List<WorkoutSession> sessions = sessionRepository.findByUser(user);

        Map<String, Long> regionBreakdown = sessions.stream()
            .collect(Collectors.groupingBy(s -> s.getRegion().name(), Collectors.counting()));

        return ResponseEntity.ok(Map.of(
            "totalSessions", sessions.size(),
            "regionBreakdown", regionBreakdown
        ));
    }
}
