package com.gymposes.controller;

import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import com.gymposes.repository.ExerciseRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.List;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ExerciseControllerTest {

    @Mock ExerciseRepository exerciseRepository;
    @InjectMocks ExerciseController exerciseController;

    @Test
    void list_returnsAllExercisesWhenNoFilters() {
        Exercise squat = Exercise.builder().id(1L).name("Squat")
            .muscleGroup(MuscleGroup.LOWER).location(ExerciseLocation.BOTH).build();
        Exercise pushup = Exercise.builder().id(2L).name("Şınav")
            .muscleGroup(MuscleGroup.UPPER).location(ExerciseLocation.HOME).build();
        when(exerciseRepository.findAll()).thenReturn(List.of(squat, pushup));

        var response = exerciseController.list(null, null);

        assertThat(response.getBody()).hasSize(2);
    }

    @Test
    void list_filtersByLocationIncludingBoth() {
        Exercise squat = Exercise.builder().id(1L).name("Squat")
            .muscleGroup(MuscleGroup.LOWER).location(ExerciseLocation.BOTH).build();
        Exercise pullup = Exercise.builder().id(2L).name("Barfiks")
            .muscleGroup(MuscleGroup.UPPER).location(ExerciseLocation.GYM).build();
        when(exerciseRepository.findAll()).thenReturn(List.of(squat, pullup));

        var response = exerciseController.list(ExerciseLocation.HOME, null);

        assertThat(response.getBody()).extracting("name").containsExactly("Squat");
    }

    @Test
    void list_filtersByMuscleGroup() {
        Exercise squat = Exercise.builder().id(1L).name("Squat")
            .muscleGroup(MuscleGroup.LOWER).location(ExerciseLocation.BOTH).build();
        Exercise pushup = Exercise.builder().id(2L).name("Şınav")
            .muscleGroup(MuscleGroup.UPPER).location(ExerciseLocation.BOTH).build();
        when(exerciseRepository.findAll()).thenReturn(List.of(squat, pushup));

        var response = exerciseController.list(null, MuscleGroup.UPPER);

        assertThat(response.getBody()).extracting("name").containsExactly("Şınav");
    }
}
