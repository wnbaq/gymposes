package com.gymposes.service;

import com.gymposes.dto.*;
import com.gymposes.entity.*;
import com.gymposes.enums.WorkoutResult;
import com.gymposes.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutService {

    private final WorkoutSessionRepository sessionRepository;
    private final SessionLogRepository sessionLogRepository;
    private final ExerciseRepository exerciseRepository;
    private final UserRepository userRepository;
    private final AdaptiveService adaptiveService;
    private final WorkoutProgramRepository programRepository;
    private final WorkoutProgramItemRepository programItemRepository;

    public WorkoutStartResponse startSession(String userEmail, WorkoutStartRequest request) {
        User user = userRepository.findByEmail(userEmail).orElseThrow();

        WorkoutSession session = WorkoutSession.builder()
            .user(user).location(request.getLocation())
            .durationMinutes(request.getDurationMinutes())
            .region(request.getRegion()).targetScore(5.0)
            .startedAt(LocalDateTime.now()).build();
        session = sessionRepository.save(session);

        Exercise first = adaptiveService.selectNextExercise(session, null);

        return WorkoutStartResponse.builder()
            .sessionId(session.getId())
            .exercise(toResponse(first))
            .remainingSeconds(request.getDurationMinutes() * 60)
            .build();
    }

    public WorkoutStartResponse startSessionFromProgram(String userEmail, StartFromProgramRequest request) {
        User user = userRepository.findByEmail(userEmail).orElseThrow();
        WorkoutProgram program = programRepository.findById(request.getProgramId())
            .orElseThrow(() -> new IllegalArgumentException("Program not found"));
        List<WorkoutProgramItem> items = programItemRepository.findByProgramOrderByOrderIndex(program);
        if (items.isEmpty()) {
            throw new IllegalStateException("Program has no exercises");
        }

        WorkoutSession session = WorkoutSession.builder()
            .user(user).program(program).currentItemIndex(0)
            .targetScore(5.0).startedAt(LocalDateTime.now()).build();
        session = sessionRepository.save(session);

        WorkoutProgramItem first = items.get(0);
        return WorkoutStartResponse.builder()
            .sessionId(session.getId())
            .exercise(toResponse(first.getExercise()))
            .remainingSeconds(0)
            .sets(first.getSets())
            .reps(first.getReps())
            .build();
    }

    public WorkoutNextResponse nextExercise(String userEmail, Long sessionId, WorkoutNextRequest request) {
        WorkoutSession session = sessionRepository.findById(sessionId).orElseThrow();
        User user = userRepository.findByEmail(userEmail).orElseThrow();
        Exercise current = exerciseRepository.findById(request.getExerciseId()).orElseThrow();

        sessionLogRepository.save(SessionLog.builder()
            .session(session).exercise(current)
            .result(request.getResult()).timestamp(LocalDateTime.now()).build());

        adaptiveService.updateUserScore(user, current, request.getResult());
        double newTarget = adaptiveService.updateTargetScore(session.getTargetScore(), request.getResult());
        session.setTargetScore(newTarget);
        sessionRepository.save(session);

        long elapsed = ChronoUnit.MINUTES.between(session.getStartedAt(), LocalDateTime.now());
        if (elapsed >= session.getDurationMinutes()) {
            return WorkoutNextResponse.builder().completed(true).build();
        }

        Exercise next = adaptiveService.selectNextExercise(session, current.getId());
        return WorkoutNextResponse.builder().exercise(toResponse(next)).completed(false).build();
    }

    public WorkoutSummaryResponse completeSession(Long sessionId) {
        WorkoutSession session = sessionRepository.findById(sessionId).orElseThrow();
        session.setCompletedAt(LocalDateTime.now());
        sessionRepository.save(session);

        List<SessionLog> logs = sessionLogRepository.findBySession(session);
        long good = logs.stream().filter(l -> l.getResult() == WorkoutResult.GOOD).count();
        long bad  = logs.stream().filter(l -> l.getResult() == WorkoutResult.BAD).count();
        long skip = logs.stream().filter(l -> l.getResult() == WorkoutResult.SKIP).count();

        return WorkoutSummaryResponse.builder()
            .sessionId(sessionId).totalExercises(logs.size())
            .goodCount((int) good).badCount((int) bad).skipCount((int) skip)
            .durationMinutes(session.getDurationMinutes()).build();
    }

    private ExerciseResponse toResponse(Exercise e) {
        return ExerciseResponse.from(e);
    }
}
