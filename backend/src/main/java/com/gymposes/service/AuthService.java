package com.gymposes.service;

import com.gymposes.dto.AuthResponse;
import com.gymposes.dto.LoginRequest;
import com.gymposes.dto.RegisterRequest;
import com.gymposes.entity.User;
import com.gymposes.repository.UserRepository;
import com.gymposes.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already in use");
        }
        User user = User.builder()
            .email(request.getEmail())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .build();
        userRepository.save(user);
        return new AuthResponse(jwtService.generateToken(user.getEmail()));
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid credentials");
        }
        return new AuthResponse(jwtService.generateToken(user.getEmail()));
    }
}
