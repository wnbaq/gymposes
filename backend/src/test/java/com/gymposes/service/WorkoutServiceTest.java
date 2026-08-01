package com.gymposes.service;

import com.gymposes.dto.WorkoutNextRequest;
import com.gymposes.dto.WorkoutStartRequest;
import com.gymposes.dto.StartFromProgramRequest;
import com.gymposes.entity.*;
import com.gymposes.enums.*;
import com.gymposes.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WorkoutServiceTest {

    @Mock WorkoutSessionRepository sessionRepository;
    @Mock SessionLogRepository sessionLogRepository;
    @Mock ExerciseRepository exerciseRepository;
    @Mock UserRepository userRepository;
    @Mock AdaptiveService adaptiveService;
    @Mock WorkoutProgramRepository programRepository;
    @Mock WorkoutProgramItemRepository programItemRepository;
    @InjectMocks WorkoutService workoutService;

    @Test
    void startSession_createsSessionAndReturnsFirstExercise() {
        User user = User.builder().id(1L).email("test@test.com").build();
        Exercise firstEx = Exercise.builder().id(10L).name("Squat")
            .defaultReps(12).lottieAssetPath("squat.json").difficultyScore(3.0).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.save(any())).thenAnswer(i -> {
            WorkoutSession s = i.getArgument(0);
            s.setId(1L);
            return s;
        });
        when(adaptiveService.selectNextExercise(any(), isNull())).thenReturn(firstEx);

        var request = new WorkoutStartRequest();
        request.setLocation(ExerciseLocation.HOME);
        request.setDurationMinutes(30);
        request.setRegion(MuscleGroup.LOWER);

        var response = workoutService.startSession("test@test.com", request);

        assertThat(response.getSessionId()).isEqualTo(1L);
        assertThat(response.getExercise().getName()).isEqualTo("Squat");
        assertThat(response.getRemainingSeconds()).isEqualTo(1800);
    }

    @Test
    void nextExercise_returnsNextExerciseWhenTimeRemains() {
        User user = User.builder().id(1L).email("test@test.com").build();
        Exercise currentEx = Exercise.builder().id(5L).build();
        Exercise nextEx = Exercise.builder().id(6L).name("Plank")
            .defaultReps(1).lottieAssetPath("plank.json").difficultyScore(3.0).build();
        WorkoutSession session = WorkoutSession.builder()
            .id(1L).user(user).targetScore(5.0).durationMinutes(30)
            .startedAt(LocalDateTime.now().minusMinutes(5))
            .build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findById(1L)).thenReturn(Optional.of(session));
        when(exerciseRepository.findById(5L)).thenReturn(Optional.of(currentEx));
        when(sessionRepository.save(any())).thenReturn(session);
        when(adaptiveService.updateTargetScore(anyDouble(), any())).thenReturn(5.5);
        when(adaptiveService.selectNextExercise(any(), eq(5L))).thenReturn(nextEx);

        var request = new WorkoutNextRequest();
        request.setExerciseId(5L);
        request.setResult(WorkoutResult.GOOD);

        var response = workoutService.nextExercise("test@test.com", 1L, request);

        assertThat(response.isCompleted()).isFalse();
        assertThat(response.getExercise().getName()).isEqualTo("Plank");
    }

    @Test
    void nextExercise_returnsCompletedWhenTimeExpired() {
        User user = User.builder().id(1L).email("test@test.com").build();
        Exercise currentEx = Exercise.builder().id(5L).build();
        WorkoutSession session = WorkoutSession.builder()
            .id(1L).user(user).targetScore(5.0).durationMinutes(30)
            .startedAt(LocalDateTime.now().minusMinutes(31))
            .build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findById(1L)).thenReturn(Optional.of(session));
        when(exerciseRepository.findById(5L)).thenReturn(Optional.of(currentEx));
        when(sessionRepository.save(any())).thenReturn(session);
        when(adaptiveService.updateTargetScore(anyDouble(), any())).thenReturn(5.5);

        var request = new WorkoutNextRequest();
        request.setExerciseId(5L);
        request.setResult(WorkoutResult.GOOD);

        var response = workoutService.nextExercise("test@test.com", 1L, request);

        assertThat(response.isCompleted()).isTrue();
        assertThat(response.getExercise()).isNull();
    }

    @Test
    void completeSession_setsCompletedAtAndReturnsSummary() {
        WorkoutSession session = WorkoutSession.builder()
            .id(1L).durationMinutes(30).build();
        List<SessionLog> logs = List.of(
            SessionLog.builder().result(WorkoutResult.GOOD).build(),
            SessionLog.builder().result(WorkoutResult.GOOD).build(),
            SessionLog.builder().result(WorkoutResult.BAD).build(),
            SessionLog.builder().result(WorkoutResult.SKIP).build()
        );

        when(sessionRepository.findById(1L)).thenReturn(Optional.of(session));
        when(sessionRepository.save(any())).thenReturn(session);
        when(sessionLogRepository.findBySession(session)).thenReturn(logs);

        var summary = workoutService.completeSession(1L);

        assertThat(summary.getTotalExercises()).isEqualTo(4);
        assertThat(summary.getGoodCount()).isEqualTo(2);
        assertThat(summary.getBadCount()).isEqualTo(1);
        assertThat(summary.getSkipCount()).isEqualTo(1);
        assertThat(summary.getDurationMinutes()).isEqualTo(30);
    }

    @Test
    void startSessionFromProgram_createsSessionAndReturnsFirstItem() {
        User user = User.builder().id(1L).email("test@test.com").build();
        WorkoutProgram program = WorkoutProgram.builder().id(5L).user(user).name("Sabah Rutini").build();
        Exercise squat = Exercise.builder().id(10L).name("Squat")
            .lottieAssetPath("squat.json").difficultyScore(3.0).build();
        WorkoutProgramItem firstItem = WorkoutProgramItem.builder()
            .id(1L).program(program).exercise(squat).sets(3).reps(12).orderIndex(0).build();
        WorkoutProgramItem secondItem = WorkoutProgramItem.builder()
            .id(2L).program(program).exercise(squat).sets(3).reps(10).orderIndex(1).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(programRepository.findById(5L)).thenReturn(Optional.of(program));
        when(programItemRepository.findByProgramOrderByOrderIndex(program))
            .thenReturn(List.of(firstItem, secondItem));
        when(sessionRepository.save(any())).thenAnswer(i -> {
            WorkoutSession s = i.getArgument(0);
            s.setId(1L);
            return s;
        });

        var request = new StartFromProgramRequest();
        request.setProgramId(5L);

        var response = workoutService.startSessionFromProgram("test@test.com", request);

        assertThat(response.getSessionId()).isEqualTo(1L);
        assertThat(response.getExercise().getName()).isEqualTo("Squat");
        assertThat(response.getSets()).isEqualTo(3);
        assertThat(response.getReps()).isEqualTo(12);
    }
}
