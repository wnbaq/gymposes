package com.gymposes.service;

import com.gymposes.dto.LoginRequest;
import com.gymposes.dto.RegisterRequest;
import com.gymposes.entity.User;
import com.gymposes.repository.UserRepository;
import com.gymposes.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtService jwtService;
    @InjectMocks AuthService authService;

    @Test
    void register_savesUserAndReturnsToken() {
        when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
        when(passwordEncoder.encode("secret")).thenReturn("hashed");
        when(jwtService.generateToken("test@example.com")).thenReturn("jwt-token");
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        var response = authService.register(new RegisterRequest("test@example.com", "secret"));

        assertThat(response.getToken()).isEqualTo("jwt-token");
        verify(userRepository).save(argThat(u -> u.getEmail().equals("test@example.com")
            && u.getPasswordHash().equals("hashed")));
    }

    @Test
    void register_throwsWhenEmailTaken() {
        when(userRepository.existsByEmail("test@example.com")).thenReturn(true);
        assertThatThrownBy(() -> authService.register(new RegisterRequest("test@example.com", "pass")))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void login_returnsTokenForValidCredentials() {
        var user = User.builder().email("test@example.com").passwordHash("hashed").build();
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("secret", "hashed")).thenReturn(true);
        when(jwtService.generateToken("test@example.com")).thenReturn("jwt-token");

        var response = authService.login(new LoginRequest("test@example.com", "secret"));

        assertThat(response.getToken()).isEqualTo("jwt-token");
    }

    @Test
    void login_throwsForWrongPassword() {
        var user = User.builder().email("test@example.com").passwordHash("hashed").build();
        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong", "hashed")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(new LoginRequest("test@example.com", "wrong")))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
