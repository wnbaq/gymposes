package com.gymposes.controller;

import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutSession;
import com.gymposes.enums.MuscleGroup;
import com.gymposes.repository.UserRepository;
import com.gymposes.repository.WorkoutSessionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock WorkoutSessionRepository sessionRepository;
    @Mock UserRepository userRepository;
    @InjectMocks UserController userController;

    private static UserDetails userDetails(String email) {
        return org.springframework.security.core.userdetails.User.builder()
            .username(email).password("x").roles("USER").build();
    }

    @Test
    void stats_bucketsProgramSessionsWithNullRegionInsteadOfThrowing() {
        User user = User.builder().id(1L).email("test@test.com").build();
        WorkoutSession regionSession = WorkoutSession.builder()
            .id(1L).user(user).region(MuscleGroup.UPPER).build();
        WorkoutSession programSession = WorkoutSession.builder()
            .id(2L).user(user).region(null).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findByUser(user)).thenReturn(List.of(regionSession, programSession));

        var response = userController.stats(userDetails("test@test.com"));

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        Map<String, Object> body = response.getBody();
        assertThat(body.get("totalSessions")).isEqualTo(2);
        @SuppressWarnings("unchecked")
        Map<String, Long> breakdown = (Map<String, Long>) body.get("regionBreakdown");
        assertThat(breakdown.get("UPPER")).isEqualTo(1L);
        assertThat(breakdown.get("PROGRAM")).isEqualTo(1L);
    }

    @Test
    void stats_returnsEmptyBreakdownWhenNoSessions() {
        User user = User.builder().id(1L).email("test@test.com").build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findByUser(user)).thenReturn(List.of());

        var response = userController.stats(userDetails("test@test.com"));

        Map<String, Object> body = response.getBody();
        assertThat(body.get("totalSessions")).isEqualTo(0);
    }
}
