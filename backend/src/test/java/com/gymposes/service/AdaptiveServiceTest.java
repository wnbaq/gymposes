package com.gymposes.service;

import com.gymposes.entity.*;
import com.gymposes.enums.*;
import com.gymposes.repository.ExerciseRepository;
import com.gymposes.repository.UserScoreRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.List;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdaptiveServiceTest {

    @Mock(lenient = true) ExerciseRepository exerciseRepository;
    @Mock(lenient = true) UserScoreRepository userScoreRepository;
    @InjectMocks AdaptiveService adaptiveService;

    private User user;
    private WorkoutSession session;
    private Exercise easy, medium, hard;

    @BeforeEach
    void setUp() {
        user = User.builder().id(1L).email("test@test.com").build();
        session = WorkoutSession.builder()
            .user(user).region(MuscleGroup.CORE)
            .location(ExerciseLocation.HOME).targetScore(5.0).build();

        easy   = Exercise.builder().id(1L).difficultyScore(2.0).muscleGroup(MuscleGroup.CORE).location(ExerciseLocation.BOTH).build();
        medium = Exercise.builder().id(2L).difficultyScore(5.0).muscleGroup(MuscleGroup.CORE).location(ExerciseLocation.BOTH).build();
        hard   = Exercise.builder().id(3L).difficultyScore(8.0).muscleGroup(MuscleGroup.CORE).location(ExerciseLocation.BOTH).build();

        when(exerciseRepository.findByMuscleGroupAndLocationIn(eq(MuscleGroup.CORE), anyList()))
            .thenReturn(List.of(easy, medium, hard));
        when(userScoreRepository.findByUserAndExerciseIn(eq(user), anyList()))
            .thenReturn(List.of());
    }

    @Test
    void selectNextExercise_choosesClosestToTargetScore() {
        // targetScore = 5.0; effectiveScore without userScore: easy=2*0.6+5*0.4=3.2, medium=5*0.6+5*0.4=5.0, hard=8*0.6+5*0.4=6.8
        Exercise selected = adaptiveService.selectNextExercise(session, null);
        assertThat(selected.getId()).isEqualTo(2L); // medium is closest to 5.0
    }

    @Test
    void selectNextExercise_skipsLastExercise() {
        // Exclude medium (id=2L), so between easy (3.2) and hard (6.8), easy is closer to 5.0
        Exercise selected = adaptiveService.selectNextExercise(session, 2L);
        assertThat(selected.getId()).isIn(1L, 3L);
    }

    @Test
    void updateTargetScore_goodIncreasesTarget() {
        double result = adaptiveService.updateTargetScore(5.0, WorkoutResult.GOOD);
        assertThat(result).isEqualTo(5.5);
    }

    @Test
    void updateTargetScore_badDecreasesTarget() {
        double result = adaptiveService.updateTargetScore(5.0, WorkoutResult.BAD);
        assertThat(result).isEqualTo(4.7);
    }

    @Test
    void updateTargetScore_skipNoChange() {
        double result = adaptiveService.updateTargetScore(5.0, WorkoutResult.SKIP);
        assertThat(result).isEqualTo(5.0);
    }

    @Test
    void updateUserScore_goodIncreasesScore() {
        when(userScoreRepository.findByUserAndExercise(user, medium))
            .thenReturn(Optional.of(UserScore.builder().user(user).exercise(medium).score(5.0).build()));

        adaptiveService.updateUserScore(user, medium, WorkoutResult.GOOD);

        verify(userScoreRepository).save(argThat(us -> us.getScore() == 6.0));
    }
}
