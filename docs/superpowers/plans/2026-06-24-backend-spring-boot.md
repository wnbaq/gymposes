# GymPoses Backend — Spring Boot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** REST API serving workout session management, adaptive exercise selection, JWT auth, and user history — all backed by PostgreSQL.

**Architecture:** Thin Client backend. All business logic lives here: exercise selection, adaptive scoring, session lifecycle. Flutter consumes these endpoints as dumb UI.

**Tech Stack:** Spring Boot 3.2.x, Spring Security 6, Spring Data JPA, PostgreSQL 15, JJWT 0.12.3, Lombok, JUnit 5, Mockito, H2 (test)

---

## File Map

```
backend/
├── pom.xml
├── src/main/java/com/gymposes/
│   ├── GymPosesApplication.java
│   ├── config/
│   │   └── SecurityConfig.java
│   ├── controller/
│   │   ├── AuthController.java
│   │   ├── WorkoutController.java
│   │   └── UserController.java
│   ├── dto/
│   │   ├── RegisterRequest.java
│   │   ├── LoginRequest.java
│   │   ├── AuthResponse.java
│   │   ├── WorkoutStartRequest.java
│   │   ├── WorkoutNextRequest.java
│   │   ├── ExerciseResponse.java
│   │   ├── WorkoutStartResponse.java
│   │   ├── WorkoutNextResponse.java
│   │   └── WorkoutSummaryResponse.java
│   ├── entity/
│   │   ├── User.java
│   │   ├── Exercise.java
│   │   ├── UserScore.java
│   │   ├── WorkoutSession.java
│   │   └── SessionLog.java
│   ├── enums/
│   │   ├── MuscleGroup.java        (UPPER, LOWER, CORE)
│   │   ├── ExerciseLocation.java   (HOME, GYM, BOTH)
│   │   └── WorkoutResult.java      (GOOD, BAD, SKIP)
│   ├── repository/
│   │   ├── UserRepository.java
│   │   ├── ExerciseRepository.java
│   │   ├── UserScoreRepository.java
│   │   ├── WorkoutSessionRepository.java
│   │   └── SessionLogRepository.java
│   ├── security/
│   │   ├── JwtService.java
│   │   ├── JwtAuthFilter.java
│   │   └── UserDetailsServiceImpl.java
│   └── service/
│       ├── AuthService.java
│       ├── AdaptiveService.java
│       ├── WorkoutService.java
│       └── DataSeeder.java
├── src/main/resources/
│   └── application.yml
└── src/test/java/com/gymposes/
    ├── service/
    │   ├── AuthServiceTest.java
    │   ├── AdaptiveServiceTest.java
    │   └── WorkoutServiceTest.java
    └── controller/
        ├── AuthControllerTest.java
        └── WorkoutControllerTest.java
```

---

## Task 1: Spring Boot Project Setup

**Files:**
- Create: `backend/pom.xml`
- Create: `backend/src/main/java/com/gymposes/GymPosesApplication.java`
- Create: `backend/src/main/resources/application.yml`
- Create: `backend/src/test/resources/application-test.yml`

- [ ] **Step 1: Generate project via Spring Initializr**

```bash
# Çalışma dizini: c:\Users\wnbaq\OneDrive\Belgeler\GymPoses
mkdir backend && cd backend
# Aşağıdaki URL'yi tarayıcıda aç ve ZIP indir, veya curl ile:
curl -o backend.zip "https://start.spring.io/starter.zip?type=maven-project&language=java&bootVersion=3.2.5&groupId=com.gymposes&artifactId=backend&name=backend&packageName=com.gymposes&javaVersion=21&dependencies=web,security,data-jpa,postgresql,lombok"
# ZIP'i backend/ klasörüne çıkar
```

- [ ] **Step 2: pom.xml'e JJWT ve H2 bağımlılıklarını ekle**

`backend/pom.xml` içinde `<dependencies>` bloğuna şunları ekle:

```xml
<!-- JJWT -->
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.3</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.3</version>
    <scope>runtime</scope>
</dependency>
<!-- H2 for tests -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
</dependency>
```

- [ ] **Step 3: application.yml yaz**

```yaml
# backend/src/main/resources/application.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/gymposesdb
    username: postgres
    password: postgres
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false
    properties:
      hibernate:
        format_sql: true

jwt:
  secret: 6D5A7134743777217A25432A462D4A614E645267556B58703273357638792F42  # 256-bit hex
  expiration: 86400000
```

- [ ] **Step 4: Test profili için application-test.yml yaz**

```yaml
# backend/src/test/resources/application-test.yml
spring:
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
    database-platform: org.hibernate.dialect.H2Dialect
```

- [ ] **Step 5: Projenin derlendiğini doğrula**

```bash
cd backend && mvn compile -q
```
Expected: `BUILD SUCCESS`

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "chore: initialize Spring Boot project with dependencies"
```

---

## Task 2: Enums ve Entity Modelleri

**Files:**
- Create: `backend/src/main/java/com/gymposes/enums/MuscleGroup.java`
- Create: `backend/src/main/java/com/gymposes/enums/ExerciseLocation.java`
- Create: `backend/src/main/java/com/gymposes/enums/WorkoutResult.java`
- Create: `backend/src/main/java/com/gymposes/entity/User.java`
- Create: `backend/src/main/java/com/gymposes/entity/Exercise.java`
- Create: `backend/src/main/java/com/gymposes/entity/UserScore.java`
- Create: `backend/src/main/java/com/gymposes/entity/WorkoutSession.java`
- Create: `backend/src/main/java/com/gymposes/entity/SessionLog.java`

- [ ] **Step 1: Enums yaz**

```java
// com/gymposes/enums/MuscleGroup.java
package com.gymposes.enums;
public enum MuscleGroup { UPPER, LOWER, CORE }

// com/gymposes/enums/ExerciseLocation.java
package com.gymposes.enums;
public enum ExerciseLocation { HOME, GYM, BOTH }

// com/gymposes/enums/WorkoutResult.java
package com.gymposes.enums;
public enum WorkoutResult { GOOD, BAD, SKIP }
```

- [ ] **Step 2: User entity yaz**

```java
// com/gymposes/entity/User.java
package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity @Table(name = "users")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
```

- [ ] **Step 3: Exercise entity yaz**

```java
// com/gymposes/entity/Exercise.java
package com.gymposes.entity;

import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "exercises")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Exercise {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    @Enumerated(EnumType.STRING)
    private MuscleGroup muscleGroup;

    @Enumerated(EnumType.STRING)
    private ExerciseLocation location;

    private Double difficultyScore;
    private Integer defaultReps;
    private String lottieAssetPath;
}
```

- [ ] **Step 4: UserScore entity yaz**

```java
// com/gymposes/entity/UserScore.java
package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_scores",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "exercise_id"}))
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UserScore {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Builder.Default
    private Double score = 5.0;
}
```

- [ ] **Step 5: WorkoutSession entity yaz**

```java
// com/gymposes/entity/WorkoutSession.java
package com.gymposes.entity;

import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "workout_sessions")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    private ExerciseLocation location;

    private Integer durationMinutes;

    @Enumerated(EnumType.STRING)
    private MuscleGroup region;

    @Builder.Default
    private Double targetScore = 5.0;

    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
}
```

- [ ] **Step 6: SessionLog entity yaz**

```java
// com/gymposes/entity/SessionLog.java
package com.gymposes.entity;

import com.gymposes.enums.WorkoutResult;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "session_logs")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SessionLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "session_id", nullable = false)
    private WorkoutSession session;

    @ManyToOne @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Enumerated(EnumType.STRING)
    private WorkoutResult result;

    private LocalDateTime timestamp;
}
```

- [ ] **Step 7: Derlemeyi doğrula**

```bash
mvn compile -q
```
Expected: `BUILD SUCCESS`

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/gymposes/entity/ backend/src/main/java/com/gymposes/enums/
git commit -m "feat: add JPA entities and enums"
```

---

## Task 3: Repository Katmanı

**Files:**
- Create: `backend/src/main/java/com/gymposes/repository/UserRepository.java`
- Create: `backend/src/main/java/com/gymposes/repository/ExerciseRepository.java`
- Create: `backend/src/main/java/com/gymposes/repository/UserScoreRepository.java`
- Create: `backend/src/main/java/com/gymposes/repository/WorkoutSessionRepository.java`
- Create: `backend/src/main/java/com/gymposes/repository/SessionLogRepository.java`

- [ ] **Step 1: Repository interface'lerini yaz**

```java
// com/gymposes/repository/UserRepository.java
package com.gymposes.repository;
import com.gymposes.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
```

```java
// com/gymposes/repository/ExerciseRepository.java
package com.gymposes.repository;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {
    List<Exercise> findByMuscleGroupAndLocationIn(MuscleGroup muscleGroup, List<ExerciseLocation> locations);
}
```

```java
// com/gymposes/repository/UserScoreRepository.java
package com.gymposes.repository;
import com.gymposes.entity.Exercise;
import com.gymposes.entity.User;
import com.gymposes.entity.UserScore;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface UserScoreRepository extends JpaRepository<UserScore, Long> {
    Optional<UserScore> findByUserAndExercise(User user, Exercise exercise);
    List<UserScore> findByUserAndExerciseIn(User user, List<Exercise> exercises);
}
```

```java
// com/gymposes/repository/WorkoutSessionRepository.java
package com.gymposes.repository;
import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {
    List<WorkoutSession> findByUserOrderByStartedAtDesc(User user);
    List<WorkoutSession> findByUser(User user);
}
```

```java
// com/gymposes/repository/SessionLogRepository.java
package com.gymposes.repository;
import com.gymposes.entity.SessionLog;
import com.gymposes.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SessionLogRepository extends JpaRepository<SessionLog, Long> {
    List<SessionLog> findBySession(WorkoutSession session);
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/gymposes/repository/
git commit -m "feat: add JPA repositories"
```

---

## Task 4: JWT Security

**Files:**
- Create: `backend/src/main/java/com/gymposes/security/JwtService.java`
- Create: `backend/src/main/java/com/gymposes/security/JwtAuthFilter.java`
- Create: `backend/src/main/java/com/gymposes/security/UserDetailsServiceImpl.java`
- Create: `backend/src/main/java/com/gymposes/config/SecurityConfig.java`

- [ ] **Step 1: JwtService yaz**

```java
// com/gymposes/security/JwtService.java
package com.gymposes.security;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.expiration}")
    private long expiration;

    public String generateToken(String email) {
        return Jwts.builder()
            .subject(email)
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getSigningKey())
            .compact();
    }

    public String extractEmail(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey()).build()
            .parseSignedClaims(token).getPayload().getSubject();
    }

    public boolean isTokenValid(String token) {
        try {
            Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token);
            return true;
        } catch (JwtException e) {
            return false;
        }
    }

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));
    }
}
```

- [ ] **Step 2: UserDetailsServiceImpl yaz**

```java
// com/gymposes/security/UserDetailsServiceImpl.java
package com.gymposes.security;

import com.gymposes.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var user = userRepository.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
        return User.builder()
            .username(user.getEmail())
            .password(user.getPasswordHash())
            .roles("USER")
            .build();
    }
}
```

- [ ] **Step 3: JwtAuthFilter yaz**

```java
// com/gymposes/security/JwtAuthFilter.java
package com.gymposes.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(req, res);
            return;
        }
        String token = header.substring(7);
        if (jwtService.isTokenValid(token)) {
            String email = jwtService.extractEmail(token);
            UserDetails userDetails = userDetailsService.loadUserByUsername(email);
            var auth = new UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.getAuthorities()
            );
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        chain.doFilter(req, res);
    }
}
```

- [ ] **Step 4: SecurityConfig yaz**

```java
// com/gymposes/config/SecurityConfig.java
package com.gymposes.config;

import com.gymposes.security.JwtAuthFilter;
import com.gymposes.security.UserDetailsServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UserDetailsServiceImpl userDetailsService;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/auth/**").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .userDetailsService(userDetailsService)
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/gymposes/security/ backend/src/main/java/com/gymposes/config/
git commit -m "feat: add JWT security layer"
```

---

## Task 5: Auth Endpoint'leri

**Files:**
- Create: `backend/src/main/java/com/gymposes/dto/RegisterRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/LoginRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/AuthResponse.java`
- Create: `backend/src/main/java/com/gymposes/service/AuthService.java`
- Create: `backend/src/main/java/com/gymposes/controller/AuthController.java`
- Test: `backend/src/test/java/com/gymposes/service/AuthServiceTest.java`

- [ ] **Step 1: Failing test yaz**

```java
// src/test/java/com/gymposes/service/AuthServiceTest.java
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
```

- [ ] **Step 2: Test'in başarısız olduğunu doğrula**

```bash
mvn test -pl . -Dtest=AuthServiceTest -q 2>&1 | tail -5
```
Expected: `COMPILATION ERROR` veya `ClassNotFoundException` (AuthService henüz yok)

- [ ] **Step 3: DTO'ları yaz**

```java
// com/gymposes/dto/RegisterRequest.java
package com.gymposes.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor
public class RegisterRequest {
    private String email;
    private String password;
}

// com/gymposes/dto/LoginRequest.java
package com.gymposes.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor
public class LoginRequest {
    private String email;
    private String password;
}

// com/gymposes/dto/AuthResponse.java
package com.gymposes.dto;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data @AllArgsConstructor
public class AuthResponse {
    private String token;
}
```

- [ ] **Step 4: AuthService yaz**

```java
// com/gymposes/service/AuthService.java
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
```

- [ ] **Step 5: AuthController yaz**

```java
// com/gymposes/controller/AuthController.java
package com.gymposes.controller;

import com.gymposes.dto.AuthResponse;
import com.gymposes.dto.LoginRequest;
import com.gymposes.dto.RegisterRequest;
import com.gymposes.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}
```

- [ ] **Step 6: Testlerin geçtiğini doğrula**

```bash
mvn test -Dtest=AuthServiceTest -q
```
Expected: `BUILD SUCCESS`, 4 test passed

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/gymposes/dto/ backend/src/main/java/com/gymposes/service/AuthService.java backend/src/main/java/com/gymposes/controller/AuthController.java backend/src/test/
git commit -m "feat: add auth endpoints with JWT"
```

---

## Task 6: Egzersiz Seed Data

**Files:**
- Create: `backend/src/main/java/com/gymposes/service/DataSeeder.java`

- [ ] **Step 1: DataSeeder yaz**

```java
// com/gymposes/service/DataSeeder.java
package com.gymposes.service;

import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import com.gymposes.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final ExerciseRepository exerciseRepository;

    @Override
    public void run(String... args) {
        if (exerciseRepository.count() > 0) return;

        exerciseRepository.saveAll(List.of(
            // UPPER - BOTH
            ex("Şınav", "Klasik şınav", MuscleGroup.UPPER, ExerciseLocation.BOTH, 3.0, 12, "pushup.json"),
            ex("Geniş Tutuş Şınav", "Geniş el pozisyonlu şınav", MuscleGroup.UPPER, ExerciseLocation.BOTH, 5.0, 10, "wide_pushup.json"),
            ex("Pike Şınav", "Kalçalar yukarda şınav", MuscleGroup.UPPER, ExerciseLocation.BOTH, 6.0, 10, "pike_pushup.json"),
            ex("Dips (Sandalye)", "Sandalyeyle triceps dips", MuscleGroup.UPPER, ExerciseLocation.HOME, 4.0, 12, "chair_dips.json"),
            ex("Diamond Şınav", "Elmas tutuş şınav", MuscleGroup.UPPER, ExerciseLocation.BOTH, 7.0, 8, "diamond_pushup.json"),
            // UPPER - GYM
            ex("Barfiks", "Ağırlıklı barfiks", MuscleGroup.UPPER, ExerciseLocation.GYM, 6.0, 8, "pullup.json"),
            ex("Dumbbell Press", "Dumbbell göğüs presi", MuscleGroup.UPPER, ExerciseLocation.GYM, 5.0, 12, "dumbbell_press.json"),
            // LOWER - BOTH
            ex("Squat", "Klasik squat", MuscleGroup.LOWER, ExerciseLocation.BOTH, 3.0, 12, "squat.json"),
            ex("Lunge", "Öne adım lunges", MuscleGroup.LOWER, ExerciseLocation.BOTH, 4.0, 12, "lunge.json"),
            ex("Sumo Squat", "Geniş duruşlu squat", MuscleGroup.LOWER, ExerciseLocation.BOTH, 4.0, 12, "sumo_squat.json"),
            ex("Jump Squat", "Sıçramalı squat", MuscleGroup.LOWER, ExerciseLocation.BOTH, 6.0, 10, "jump_squat.json"),
            // LOWER - GYM
            ex("Leg Press", "Leg press makinesi", MuscleGroup.LOWER, ExerciseLocation.GYM, 5.0, 12, "leg_press.json"),
            ex("Romanian Deadlift", "Romanian deadlift", MuscleGroup.LOWER, ExerciseLocation.GYM, 7.0, 10, "rdl.json"),
            // CORE - BOTH
            ex("Plank", "30 sn statik plank", MuscleGroup.CORE, ExerciseLocation.BOTH, 3.0, 1, "plank.json"),
            ex("Mekik", "Klasik mekik", MuscleGroup.CORE, ExerciseLocation.BOTH, 3.0, 15, "crunch.json"),
            ex("Bisiklet Mekik", "Çapraz mekik", MuscleGroup.CORE, ExerciseLocation.BOTH, 5.0, 15, "bicycle_crunch.json"),
            ex("Mountain Climber", "Koşar adım egzersizi", MuscleGroup.CORE, ExerciseLocation.BOTH, 6.0, 20, "mountain_climber.json"),
            ex("Leg Raise", "Yatarak bacak kaldırma", MuscleGroup.CORE, ExerciseLocation.BOTH, 5.0, 12, "leg_raise.json")
        ));
    }

    private Exercise ex(String name, String desc, MuscleGroup mg, ExerciseLocation loc,
                        double diff, int reps, String lottiePath) {
        return Exercise.builder()
            .name(name).description(desc).muscleGroup(mg).location(loc)
            .difficultyScore(diff).defaultReps(reps).lottieAssetPath(lottiePath)
            .build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/gymposes/service/DataSeeder.java
git commit -m "feat: add exercise seed data (18 exercises)"
```

---

## Task 7: Adaptive Algorithm Service

**Files:**
- Create: `backend/src/main/java/com/gymposes/service/AdaptiveService.java`
- Test: `backend/src/test/java/com/gymposes/service/AdaptiveServiceTest.java`

- [ ] **Step 1: Failing test yaz**

```java
// src/test/java/com/gymposes/service/AdaptiveServiceTest.java
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

    @Mock ExerciseRepository exerciseRepository;
    @Mock UserScoreRepository userScoreRepository;
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
```

- [ ] **Step 2: Test'in başarısız olduğunu doğrula**

```bash
mvn test -Dtest=AdaptiveServiceTest -q 2>&1 | tail -5
```
Expected: Compilation error (AdaptiveService yok)

- [ ] **Step 3: AdaptiveService implement et**

```java
// com/gymposes/service/AdaptiveService.java
package com.gymposes.service;

import com.gymposes.entity.*;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.WorkoutResult;
import com.gymposes.repository.ExerciseRepository;
import com.gymposes.repository.UserScoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdaptiveService {

    private final ExerciseRepository exerciseRepository;
    private final UserScoreRepository userScoreRepository;

    public Exercise selectNextExercise(WorkoutSession session, Long excludeExerciseId) {
        List<Exercise> candidates = exerciseRepository.findByMuscleGroupAndLocationIn(
            session.getRegion(),
            List.of(session.getLocation(), ExerciseLocation.BOTH)
        );

        Map<Long, Double> userScores = userScoreRepository
            .findByUserAndExerciseIn(session.getUser(), candidates)
            .stream()
            .collect(Collectors.toMap(us -> us.getExercise().getId(), UserScore::getScore));

        double targetScore = session.getTargetScore();

        return candidates.stream()
            .filter(e -> !e.getId().equals(excludeExerciseId))
            .min(Comparator.comparingDouble(e -> {
                double uScore = userScores.getOrDefault(e.getId(), 5.0);
                double effectiveScore = e.getDifficultyScore() * 0.6 + uScore * 0.4;
                return Math.abs(effectiveScore - targetScore);
            }))
            .orElse(candidates.get(0));
    }

    public void updateUserScore(User user, Exercise exercise, WorkoutResult result) {
        UserScore score = userScoreRepository.findByUserAndExercise(user, exercise)
            .orElse(UserScore.builder().user(user).exercise(exercise).score(5.0).build());

        switch (result) {
            case GOOD -> score.setScore(score.getScore() + 1.0);
            case BAD  -> score.setScore(score.getScore() - 0.5);
            case SKIP -> { /* no change */ }
        }
        userScoreRepository.save(score);
    }

    public double updateTargetScore(double current, WorkoutResult result) {
        return switch (result) {
            case GOOD -> current + 0.5;
            case BAD  -> current - 0.3;
            case SKIP -> current;
        };
    }
}
```

- [ ] **Step 4: Testlerin geçtiğini doğrula**

```bash
mvn test -Dtest=AdaptiveServiceTest -q
```
Expected: `BUILD SUCCESS`, 6 test passed

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/gymposes/service/AdaptiveService.java backend/src/test/java/com/gymposes/service/AdaptiveServiceTest.java
git commit -m "feat: add adaptive exercise selection algorithm"
```

---

## Task 8: Workout Endpoint'leri

**Files:**
- Create: `backend/src/main/java/com/gymposes/dto/WorkoutStartRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/WorkoutNextRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/ExerciseResponse.java`
- Create: `backend/src/main/java/com/gymposes/dto/WorkoutStartResponse.java`
- Create: `backend/src/main/java/com/gymposes/dto/WorkoutNextResponse.java`
- Create: `backend/src/main/java/com/gymposes/dto/WorkoutSummaryResponse.java`
- Create: `backend/src/main/java/com/gymposes/service/WorkoutService.java`
- Create: `backend/src/main/java/com/gymposes/controller/WorkoutController.java`
- Test: `backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java`

- [ ] **Step 1: DTO'ları yaz**

```java
// com/gymposes/dto/WorkoutStartRequest.java
package com.gymposes.dto;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import lombok.Data;

@Data
public class WorkoutStartRequest {
    private ExerciseLocation location;
    private Integer durationMinutes;
    private MuscleGroup region;
}

// com/gymposes/dto/WorkoutNextRequest.java
package com.gymposes.dto;
import com.gymposes.enums.WorkoutResult;
import lombok.Data;

@Data
public class WorkoutNextRequest {
    private Long exerciseId;
    private WorkoutResult result;
}

// com/gymposes/dto/ExerciseResponse.java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class ExerciseResponse {
    private Long id;
    private String name;
    private String description;
    private Integer defaultReps;
    private String lottieAssetPath;
    private Double difficultyScore;
}

// com/gymposes/dto/WorkoutStartResponse.java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutStartResponse {
    private Long sessionId;
    private ExerciseResponse exercise;
    private Integer remainingSeconds;
}

// com/gymposes/dto/WorkoutNextResponse.java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutNextResponse {
    private ExerciseResponse exercise;
    private boolean completed;
}

// com/gymposes/dto/WorkoutSummaryResponse.java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutSummaryResponse {
    private Long sessionId;
    private Integer totalExercises;
    private Integer goodCount;
    private Integer badCount;
    private Integer skipCount;
    private Integer durationMinutes;
}
```

- [ ] **Step 2: Failing test yaz**

```java
// src/test/java/com/gymposes/service/WorkoutServiceTest.java
package com.gymposes.service;

import com.gymposes.dto.WorkoutStartRequest;
import com.gymposes.entity.*;
import com.gymposes.enums.*;
import com.gymposes.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
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
}
```

- [ ] **Step 3: Test başarısız olduğunu doğrula**

```bash
mvn test -Dtest=WorkoutServiceTest -q 2>&1 | tail -5
```
Expected: Compilation error

- [ ] **Step 4: WorkoutService implement et**

```java
// com/gymposes/service/WorkoutService.java
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

    public WorkoutStartResponse startSession(String userEmail, WorkoutStartRequest request) {
        User user = userRepository.findByEmail(userEmail).orElseThrow();

        WorkoutSession session = WorkoutSession.builder()
            .user(user).location(request.getLocation())
            .durationMinutes(request.getDurationMinutes())
            .region(request.getRegion()).targetScore(5.0)
            .startedAt(LocalDateTime.now()).build();
        session = sessionRepository.save(session);

        Exercise first = adaptiveService.selectNextExercise(session, null);

        sessionLogRepository.save(SessionLog.builder()
            .session(session).exercise(first).timestamp(LocalDateTime.now()).build());

        return WorkoutStartResponse.builder()
            .sessionId(session.getId())
            .exercise(toResponse(first))
            .remainingSeconds(request.getDurationMinutes() * 60)
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
        return ExerciseResponse.builder()
            .id(e.getId()).name(e.getName()).description(e.getDescription())
            .defaultReps(e.getDefaultReps()).lottieAssetPath(e.getLottieAssetPath())
            .difficultyScore(e.getDifficultyScore()).build();
    }
}
```

- [ ] **Step 5: WorkoutController implement et**

```java
// com/gymposes/controller/WorkoutController.java
package com.gymposes.controller;

import com.gymposes.dto.*;
import com.gymposes.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/workout")
@RequiredArgsConstructor
public class WorkoutController {

    private final WorkoutService workoutService;

    @PostMapping("/start")
    public ResponseEntity<WorkoutStartResponse> start(
            @RequestBody WorkoutStartRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(workoutService.startSession(user.getUsername(), request));
    }

    @PostMapping("/{sessionId}/next")
    public ResponseEntity<WorkoutNextResponse> next(
            @PathVariable Long sessionId,
            @RequestBody WorkoutNextRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(workoutService.nextExercise(user.getUsername(), sessionId, request));
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<WorkoutSummaryResponse> complete(@PathVariable Long sessionId) {
        return ResponseEntity.ok(workoutService.completeSession(sessionId));
    }
}
```

- [ ] **Step 6: Testleri geç**

```bash
mvn test -Dtest=WorkoutServiceTest -q
```
Expected: `BUILD SUCCESS`

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/gymposes/dto/ backend/src/main/java/com/gymposes/service/WorkoutService.java backend/src/main/java/com/gymposes/controller/WorkoutController.java backend/src/test/
git commit -m "feat: add workout session endpoints"
```

---

## Task 9: History ve Profile Endpoint'leri

**Files:**
- Create: `backend/src/main/java/com/gymposes/controller/UserController.java`

- [ ] **Step 1: UserController yaz**

```java
// com/gymposes/controller/UserController.java
package com.gymposes.controller;

import com.gymposes.entity.*;
import com.gymposes.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
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
```

- [ ] **Step 2: Tüm testleri çalıştır**

```bash
mvn test -q
```
Expected: `BUILD SUCCESS`, tüm testler yeşil

- [ ] **Step 3: PostgreSQL ile entegrasyon testi**

```bash
# PostgreSQL çalışıyor olmalı
createdb gymposesdb  # veya pgAdmin'den oluştur
mvn spring-boot:run &
sleep 5

# Register
curl -s -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' | python -m json.tool

# Login ve token al
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}' | python -c "import sys,json;print(json.load(sys.stdin)['token'])")

# Workout başlat
curl -s -X POST http://localhost:8080/workout/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"location":"HOME","durationMinutes":30,"region":"CORE"}' | python -m json.tool
```
Expected: sessionId ve ilk egzersiz JSON olarak gelir

- [ ] **Step 4: Sunucuyu durdur ve final commit**

```bash
kill %1  # arka planda çalışan mvn'i durdur
git add backend/src/main/java/com/gymposes/controller/UserController.java
git commit -m "feat: add history and profile stats endpoints — backend complete"
```

---

## Backend Tamamlandı

Backend tamamen bağımsız çalışır durumda. Flutter planına geçmek için: `docs/superpowers/plans/2026-06-24-flutter-frontend.md`
