package com.gymposes.service;

import com.gymposes.dto.CreateProgramRequest;
import com.gymposes.dto.ProgramItemRequest;
import com.gymposes.entity.*;
import com.gymposes.repository.*;
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
class ProgramServiceTest {

    @Mock WorkoutProgramRepository programRepository;
    @Mock WorkoutProgramItemRepository programItemRepository;
    @Mock ExerciseRepository exerciseRepository;
    @Mock UserRepository userRepository;
    @InjectMocks ProgramService programService;

    @Test
    void createProgram_savesProgramAndItems() {
        User user = User.builder().id(1L).email("test@test.com").build();
        Exercise squat = Exercise.builder().id(10L).name("Squat").build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(programRepository.save(any())).thenAnswer(i -> {
            WorkoutProgram p = i.getArgument(0);
            p.setId(1L);
            return p;
        });
        when(exerciseRepository.findById(10L)).thenReturn(Optional.of(squat));
        when(programItemRepository.saveAll(any())).thenAnswer(i -> i.getArgument(0));

        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(10L);
        itemRequest.setSets(3);
        itemRequest.setReps(12);
        itemRequest.setOrderIndex(0);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        var response = programService.createProgram("test@test.com", request);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getName()).isEqualTo("Sabah Rutini");
        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().get(0).getExerciseId()).isEqualTo(10L);
        assertThat(response.getItems().get(0).getSets()).isEqualTo(3);
    }

    @Test
    void createProgram_throwsWhenNameBlank() {
        var request = new CreateProgramRequest();
        request.setName("  ");
        request.setItems(List.of(new ProgramItemRequest()));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenItemsEmpty() {
        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of());

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenSetsIsNull() {
        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(10L);
        itemRequest.setSets(null);
        itemRequest.setReps(12);
        itemRequest.setOrderIndex(0);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenSetsIsZeroOrNegative() {
        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(10L);
        itemRequest.setSets(0);
        itemRequest.setReps(12);
        itemRequest.setOrderIndex(0);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenRepsIsNull() {
        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(10L);
        itemRequest.setSets(3);
        itemRequest.setReps(null);
        itemRequest.setOrderIndex(0);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenOrderIndexIsNull() {
        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(10L);
        itemRequest.setSets(3);
        itemRequest.setReps(12);
        itemRequest.setOrderIndex(null);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void createProgram_throwsWhenExerciseIdIsNull() {
        var itemRequest = new ProgramItemRequest();
        itemRequest.setExerciseId(null);
        itemRequest.setSets(3);
        itemRequest.setReps(12);
        itemRequest.setOrderIndex(0);

        var request = new CreateProgramRequest();
        request.setName("Sabah Rutini");
        request.setItems(List.of(itemRequest));

        assertThatThrownBy(() -> programService.createProgram("test@test.com", request))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void listPrograms_returnsUsersProgramsWithItems() {
        User user = User.builder().id(1L).email("test@test.com").build();
        WorkoutProgram program = WorkoutProgram.builder().id(1L).user(user).name("Sabah Rutini").build();
        Exercise squat = Exercise.builder().id(10L).name("Squat").build();
        WorkoutProgramItem item = WorkoutProgramItem.builder()
            .id(1L).program(program).exercise(squat).sets(3).reps(12).orderIndex(0).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(programRepository.findByUser(user)).thenReturn(List.of(program));
        when(programItemRepository.findByProgramOrderByOrderIndex(program)).thenReturn(List.of(item));

        var result = programService.listPrograms("test@test.com");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Sabah Rutini");
        assertThat(result.get(0).getItems()).hasSize(1);
    }
}
