# Custom Workout Program Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user browse the exercise catalog, assemble their own named workout program (exercise + sets + reps per item), save it, and run a session that walks through it in a fixed order instead of the adaptive engine.

**Architecture:** Two new backend entities (`WorkoutProgram`, `WorkoutProgramItem`) plus two nullable fields on the existing `WorkoutSession` (`program`, `currentItemIndex`) that flip a session into "program mode." `WorkoutService.nextExercise` branches on `session.getProgram() != null` to walk the program's items instead of calling `AdaptiveService`. On mobile, a new `programs` feature (provider + two screens) reuses the existing `ExerciseScreen`/`SessionNotifier` machinery — program-mode sessions are still ordinary `WorkoutSession`s with `SessionLog` rows and a summary at the end.

**Tech Stack:** Spring Boot 3 / Spring Data JPA / Lombok (backend), Flutter / Riverpod / Dio / go_router (mobile). No new dependencies.

## Global Constraints

- Every new/modified backend endpoint requires JWT auth (default `anyRequest().authenticated()` in `SecurityConfig` — no config change needed)
- Backend tests follow the existing convention: plain JUnit 5 + Mockito with `@InjectMocks`, no `@WebMvcTest`/`@DataJpaTest`/Spring context (see `WorkoutServiceTest`, `AuthServiceTest`)
- Mobile tests follow the existing convention: pure state/logic unit tests with `flutter_test`, no Dio mocking (see `session_provider_test.dart`)
- `ddl-auto: create-drop` — new entities need no migration, tables are created on startup
- Enum wire values are the Java enum names verbatim (`HOME`/`GYM`/`BOTH`, `UPPER`/`LOWER`/`CORE`) — mobile already sends/parses these as raw strings
- Follow existing Lombok entity style: `@Data @EqualsAndHashCode(onlyExplicitlyIncluded = true) @NoArgsConstructor @AllArgsConstructor @Builder` with `@Id @EqualsAndHashCode.Include` for entities holding `@ManyToOne` relations (matches `WorkoutSession`, `SessionLog`)

---

## Task 1: Program Data Model (entities + repositories)

**Files:**
- Create: `backend/src/main/java/com/gymposes/entity/WorkoutProgram.java`
- Create: `backend/src/main/java/com/gymposes/entity/WorkoutProgramItem.java`
- Create: `backend/src/main/java/com/gymposes/repository/WorkoutProgramRepository.java`
- Create: `backend/src/main/java/com/gymposes/repository/WorkoutProgramItemRepository.java`
- Modify: `backend/src/main/java/com/gymposes/entity/WorkoutSession.java`

**Interfaces:**
- Produces: `WorkoutProgram{id, user, name, createdAt}`, `WorkoutProgramItem{id, program, exercise, sets, reps, orderIndex}`, `WorkoutProgramRepository.findByUser(User): List<WorkoutProgram>`, `WorkoutProgramItemRepository.findByProgramOrderByOrderIndex(WorkoutProgram): List<WorkoutProgramItem>`, `WorkoutSession.program: WorkoutProgram` (nullable), `WorkoutSession.currentItemIndex: Integer` (nullable)

There's no meaningful unit to TDD here — these are plain JPA mappings with no logic, matching the existing `Exercise`/`User`/`WorkoutSession` entities, none of which have dedicated tests. Verify with a compile instead.

- [ ] **Step 1: Create the `WorkoutProgram` entity**

```java
package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity @Table(name = "workout_programs")
@Data @EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutProgram {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String name;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
```

- [ ] **Step 2: Create the `WorkoutProgramItem` entity**

```java
package com.gymposes.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "workout_program_items")
@Data @EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutProgramItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "program_id", nullable = false)
    private WorkoutProgram program;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Column(nullable = false)
    private Integer sets;

    @Column(nullable = false)
    private Integer reps;

    @Column(nullable = false)
    private Integer orderIndex;
}
```

- [ ] **Step 3: Create the repositories**

```java
package com.gymposes.repository;
import com.gymposes.entity.User;
import com.gymposes.entity.WorkoutProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutProgramRepository extends JpaRepository<WorkoutProgram, Long> {
    List<WorkoutProgram> findByUser(User user);
}
```

```java
package com.gymposes.repository;
import com.gymposes.entity.WorkoutProgram;
import com.gymposes.entity.WorkoutProgramItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface WorkoutProgramItemRepository extends JpaRepository<WorkoutProgramItem, Long> {
    List<WorkoutProgramItem> findByProgramOrderByOrderIndex(WorkoutProgram program);
}
```

- [ ] **Step 4: Add `program` and `currentItemIndex` to `WorkoutSession`**

In `backend/src/main/java/com/gymposes/entity/WorkoutSession.java`, add these two fields (after the existing `targetScore` field, before `startedAt`):

```java
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "program_id")
    private WorkoutProgram program;

    private Integer currentItemIndex;
```

- [ ] **Step 5: Compile to verify the mapping is valid**

Run: `cd backend && mvn -q compile`
Expected: `BUILD SUCCESS`, no output on success (Maven is quiet-mode)

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/gymposes/entity/WorkoutProgram.java backend/src/main/java/com/gymposes/entity/WorkoutProgramItem.java backend/src/main/java/com/gymposes/repository/WorkoutProgramRepository.java backend/src/main/java/com/gymposes/repository/WorkoutProgramItemRepository.java backend/src/main/java/com/gymposes/entity/WorkoutSession.java
git commit -m "feat(backend): add WorkoutProgram data model"
```

---

## Task 2: `GET /exercises` Catalog Endpoint

**Files:**
- Modify: `backend/src/main/java/com/gymposes/dto/ExerciseResponse.java`
- Modify: `backend/src/main/java/com/gymposes/service/WorkoutService.java`
- Create: `backend/src/main/java/com/gymposes/controller/ExerciseController.java`
- Create: `backend/src/test/java/com/gymposes/controller/ExerciseControllerTest.java`

**Interfaces:**
- Consumes: `ExerciseRepository` (existing, `backend/src/main/java/com/gymposes/repository/ExerciseRepository.java`), `Exercise` entity (existing)
- Produces: `ExerciseResponse.from(Exercise): ExerciseResponse` (static factory, now also carrying `muscleGroup`/`location`), `GET /exercises?location=&muscleGroup=` → `List<ExerciseResponse>`

- [ ] **Step 1: Add `muscleGroup`/`location` to `ExerciseResponse` and a static factory**

Replace the full contents of `backend/src/main/java/com/gymposes/dto/ExerciseResponse.java`:

```java
package com.gymposes.dto;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
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
    private MuscleGroup muscleGroup;
    private ExerciseLocation location;

    public static ExerciseResponse from(Exercise e) {
        return ExerciseResponse.builder()
            .id(e.getId()).name(e.getName()).description(e.getDescription())
            .defaultReps(e.getDefaultReps()).lottieAssetPath(e.getLottieAssetPath())
            .difficultyScore(e.getDifficultyScore())
            .muscleGroup(e.getMuscleGroup()).location(e.getLocation())
            .build();
    }
}
```

- [ ] **Step 2: Point `WorkoutService.toResponse` at the new factory**

In `backend/src/main/java/com/gymposes/service/WorkoutService.java`, replace the private `toResponse` method body:

```java
    private ExerciseResponse toResponse(Exercise e) {
        return ExerciseResponse.from(e);
    }
```

- [ ] **Step 3: Run existing `WorkoutServiceTest` to confirm no regression**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest`
Expected: `BUILD SUCCESS`, all 4 existing tests pass (they assert on `name`/`sessionId`/etc, unaffected by the new `muscleGroup`/`location` fields)

- [ ] **Step 4: Write the failing test for `ExerciseController`**

Create `backend/src/test/java/com/gymposes/controller/ExerciseControllerTest.java`:

```java
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
```

- [ ] **Step 5: Run the test to verify it fails (class doesn't exist yet)**

Run: `cd backend && mvn -q test -Dtest=ExerciseControllerTest`
Expected: FAIL — compile error, `ExerciseController` does not exist

- [ ] **Step 6: Create `ExerciseController`**

```java
package com.gymposes.controller;

import com.gymposes.dto.ExerciseResponse;
import com.gymposes.entity.Exercise;
import com.gymposes.enums.ExerciseLocation;
import com.gymposes.enums.MuscleGroup;
import com.gymposes.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseRepository exerciseRepository;

    @GetMapping
    public ResponseEntity<List<ExerciseResponse>> list(
            @RequestParam(required = false) ExerciseLocation location,
            @RequestParam(required = false) MuscleGroup muscleGroup) {
        List<Exercise> exercises = exerciseRepository.findAll().stream()
            .filter(e -> location == null || e.getLocation() == location || e.getLocation() == ExerciseLocation.BOTH)
            .filter(e -> muscleGroup == null || e.getMuscleGroup() == muscleGroup)
            .toList();
        return ResponseEntity.ok(exercises.stream().map(ExerciseResponse::from).toList());
    }
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `cd backend && mvn -q test -Dtest=ExerciseControllerTest`
Expected: `BUILD SUCCESS`, 3 tests pass

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/gymposes/dto/ExerciseResponse.java backend/src/main/java/com/gymposes/service/WorkoutService.java backend/src/main/java/com/gymposes/controller/ExerciseController.java backend/src/test/java/com/gymposes/controller/ExerciseControllerTest.java
git commit -m "feat(backend): add GET /exercises catalog endpoint"
```

---

## Task 3: Program Creation & Listing

**Files:**
- Create: `backend/src/main/java/com/gymposes/dto/ProgramItemRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/CreateProgramRequest.java`
- Create: `backend/src/main/java/com/gymposes/dto/ProgramItemResponse.java`
- Create: `backend/src/main/java/com/gymposes/dto/ProgramResponse.java`
- Create: `backend/src/main/java/com/gymposes/service/ProgramService.java`
- Create: `backend/src/main/java/com/gymposes/controller/ProgramController.java`
- Create: `backend/src/test/java/com/gymposes/service/ProgramServiceTest.java`

**Interfaces:**
- Consumes: `WorkoutProgramRepository`, `WorkoutProgramItemRepository`, `ExerciseRepository`, `UserRepository` (Task 1 / existing)
- Produces: `ProgramService.createProgram(String userEmail, CreateProgramRequest): ProgramResponse`, `ProgramService.listPrograms(String userEmail): List<ProgramResponse>`, `POST /programs`, `GET /programs`

- [ ] **Step 1: Create the request/response DTOs**

`backend/src/main/java/com/gymposes/dto/ProgramItemRequest.java`:
```java
package com.gymposes.dto;
import lombok.Data;

@Data
public class ProgramItemRequest {
    private Long exerciseId;
    private Integer sets;
    private Integer reps;
    private Integer orderIndex;
}
```

`backend/src/main/java/com/gymposes/dto/CreateProgramRequest.java`:
```java
package com.gymposes.dto;
import lombok.Data;
import java.util.List;

@Data
public class CreateProgramRequest {
    private String name;
    private List<ProgramItemRequest> items;
}
```

`backend/src/main/java/com/gymposes/dto/ProgramItemResponse.java`:
```java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class ProgramItemResponse {
    private Long exerciseId;
    private Integer sets;
    private Integer reps;
    private Integer orderIndex;
}
```

`backend/src/main/java/com/gymposes/dto/ProgramResponse.java`:
```java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data @Builder
public class ProgramResponse {
    private Long id;
    private String name;
    private List<ProgramItemResponse> items;
}
```

- [ ] **Step 2: Write the failing test for `ProgramService`**

Create `backend/src/test/java/com/gymposes/service/ProgramServiceTest.java`:

```java
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd backend && mvn -q test -Dtest=ProgramServiceTest`
Expected: FAIL — compile error, `ProgramService` does not exist

- [ ] **Step 4: Implement `ProgramService`**

```java
package com.gymposes.service;

import com.gymposes.dto.*;
import com.gymposes.entity.*;
import com.gymposes.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ProgramService {

    private final WorkoutProgramRepository programRepository;
    private final WorkoutProgramItemRepository programItemRepository;
    private final ExerciseRepository exerciseRepository;
    private final UserRepository userRepository;

    public ProgramResponse createProgram(String userEmail, CreateProgramRequest request) {
        if (request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Program name is required");
        }
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new IllegalArgumentException("Program must have at least one exercise");
        }

        User user = userRepository.findByEmail(userEmail).orElseThrow();
        WorkoutProgram program = programRepository.save(
            WorkoutProgram.builder().user(user).name(request.getName()).build());

        List<WorkoutProgramItem> items = request.getItems().stream()
            .map(i -> WorkoutProgramItem.builder()
                .program(program)
                .exercise(exerciseRepository.findById(i.getExerciseId())
                    .orElseThrow(() -> new IllegalArgumentException("Unknown exercise: " + i.getExerciseId())))
                .sets(i.getSets())
                .reps(i.getReps())
                .orderIndex(i.getOrderIndex())
                .build())
            .toList();
        programItemRepository.saveAll(items);

        return toResponse(program, items);
    }

    public List<ProgramResponse> listPrograms(String userEmail) {
        User user = userRepository.findByEmail(userEmail).orElseThrow();
        return programRepository.findByUser(user).stream()
            .map(p -> toResponse(p, programItemRepository.findByProgramOrderByOrderIndex(p)))
            .toList();
    }

    private ProgramResponse toResponse(WorkoutProgram program, List<WorkoutProgramItem> items) {
        return ProgramResponse.builder()
            .id(program.getId())
            .name(program.getName())
            .items(items.stream().map(i -> ProgramItemResponse.builder()
                .exerciseId(i.getExercise().getId())
                .sets(i.getSets())
                .reps(i.getReps())
                .orderIndex(i.getOrderIndex())
                .build()).toList())
            .build();
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd backend && mvn -q test -Dtest=ProgramServiceTest`
Expected: `BUILD SUCCESS`, 4 tests pass

- [ ] **Step 6: Create `ProgramController`**

```java
package com.gymposes.controller;

import com.gymposes.dto.CreateProgramRequest;
import com.gymposes.dto.ProgramResponse;
import com.gymposes.service.ProgramService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/programs")
@RequiredArgsConstructor
public class ProgramController {

    private final ProgramService programService;

    @PostMapping
    public ResponseEntity<ProgramResponse> create(
            @RequestBody CreateProgramRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(programService.createProgram(user.getUsername(), request));
    }

    @GetMapping
    public ResponseEntity<List<ProgramResponse>> list(@AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(programService.listPrograms(user.getUsername()));
    }
}
```

- [ ] **Step 7: Compile the full backend to confirm the controller wires up**

Run: `cd backend && mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/gymposes/dto/ProgramItemRequest.java backend/src/main/java/com/gymposes/dto/CreateProgramRequest.java backend/src/main/java/com/gymposes/dto/ProgramItemResponse.java backend/src/main/java/com/gymposes/dto/ProgramResponse.java backend/src/main/java/com/gymposes/service/ProgramService.java backend/src/main/java/com/gymposes/controller/ProgramController.java backend/src/test/java/com/gymposes/service/ProgramServiceTest.java
git commit -m "feat(backend): add POST/GET /programs endpoints"
```

---

## Task 4: Start a Session From a Program

**Files:**
- Modify: `backend/src/main/java/com/gymposes/dto/WorkoutStartResponse.java`
- Modify: `backend/src/main/java/com/gymposes/dto/WorkoutNextResponse.java`
- Create: `backend/src/main/java/com/gymposes/dto/StartFromProgramRequest.java`
- Modify: `backend/src/main/java/com/gymposes/service/WorkoutService.java`
- Modify: `backend/src/main/java/com/gymposes/controller/WorkoutController.java`
- Modify: `backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java`

**Interfaces:**
- Consumes: `WorkoutProgramRepository`, `WorkoutProgramItemRepository` (Task 1), `ExerciseResponse.from` (Task 2)
- Produces: `WorkoutService.startSessionFromProgram(String userEmail, StartFromProgramRequest): WorkoutStartResponse`, `POST /workout/start-from-program`, `WorkoutStartResponse.sets/reps: Integer` (nullable), `WorkoutNextResponse.sets/reps: Integer` (nullable)

- [ ] **Step 1: Add `sets`/`reps` to `WorkoutStartResponse` and `WorkoutNextResponse`**

`backend/src/main/java/com/gymposes/dto/WorkoutStartResponse.java`:
```java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutStartResponse {
    private Long sessionId;
    private ExerciseResponse exercise;
    private Integer remainingSeconds;
    private Integer sets;
    private Integer reps;
}
```

`backend/src/main/java/com/gymposes/dto/WorkoutNextResponse.java`:
```java
package com.gymposes.dto;
import lombok.Builder;
import lombok.Data;

@Data @Builder
public class WorkoutNextResponse {
    private ExerciseResponse exercise;
    private boolean completed;
    private Integer sets;
    private Integer reps;
}
```

- [ ] **Step 2: Create `StartFromProgramRequest`**

```java
package com.gymposes.dto;
import lombok.Data;

@Data
public class StartFromProgramRequest {
    private Long programId;
}
```

- [ ] **Step 3: Run existing `WorkoutServiceTest` to confirm no regression from the DTO change**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest`
Expected: `BUILD SUCCESS` — new fields default to `null` via `@Builder`, existing assertions don't touch them

- [ ] **Step 4: Write the failing test for `startSessionFromProgram`**

Add to `backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java`. First, add two new mocks to the class (alongside the existing `@Mock` fields):

```java
    @Mock WorkoutProgramRepository programRepository;
    @Mock WorkoutProgramItemRepository programItemRepository;
```

Then add this test method:

```java
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
```

Also add the matching imports at the top of the file: `com.gymposes.dto.StartFromProgramRequest` (the `com.gymposes.dto.*` wildcard import already present covers this — no import change needed since the file already does `import com.gymposes.dto.*;` and `import com.gymposes.entity.*;` and `import com.gymposes.repository.*;`).

- [ ] **Step 5: Run the test to verify it fails**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest#startSessionFromProgram_createsSessionAndReturnsFirstItem`
Expected: FAIL — compile error, `WorkoutService.startSessionFromProgram` does not exist

- [ ] **Step 6: Implement `startSessionFromProgram`**

In `backend/src/main/java/com/gymposes/service/WorkoutService.java`:
1. Add two new `final` fields alongside the existing ones (`WorkoutProgramRepository programRepository;` and `WorkoutProgramItemRepository programItemRepository;`) — `@RequiredArgsConstructor` picks them up automatically
2. Add this method after `startSession`:

```java
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
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest`
Expected: `BUILD SUCCESS`, all tests (existing 4 + new 1) pass

- [ ] **Step 8: Add the controller endpoint**

In `backend/src/main/java/com/gymposes/controller/WorkoutController.java`, add after the `start` method:

```java
    @PostMapping("/start-from-program")
    public ResponseEntity<WorkoutStartResponse> startFromProgram(
            @RequestBody StartFromProgramRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(workoutService.startSessionFromProgram(user.getUsername(), request));
    }
```

- [ ] **Step 9: Compile to confirm the controller wires up**

Run: `cd backend && mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 10: Commit**

```bash
git add backend/src/main/java/com/gymposes/dto/WorkoutStartResponse.java backend/src/main/java/com/gymposes/dto/WorkoutNextResponse.java backend/src/main/java/com/gymposes/dto/StartFromProgramRequest.java backend/src/main/java/com/gymposes/service/WorkoutService.java backend/src/main/java/com/gymposes/controller/WorkoutController.java backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java
git commit -m "feat(backend): add POST /workout/start-from-program"
```

---

## Task 5: Program-Mode Branching in `nextExercise`

**Files:**
- Modify: `backend/src/main/java/com/gymposes/service/WorkoutService.java`
- Modify: `backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java`

**Interfaces:**
- Consumes: `WorkoutProgramItemRepository.findByProgramOrderByOrderIndex` (Task 1), `WorkoutSession.program`/`currentItemIndex` (Task 1)
- Produces: `WorkoutService.nextExercise` now branches — program-mode sessions no longer call `AdaptiveService`

- [ ] **Step 1: Write the failing tests for program-mode `nextExercise`**

Add to `backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java`:

```java
    @Test
    void nextExercise_programMode_returnsNextItemInOrder() {
        User user = User.builder().id(1L).email("test@test.com").build();
        WorkoutProgram program = WorkoutProgram.builder().id(5L).build();
        Exercise squat = Exercise.builder().id(10L).build();
        Exercise lunge = Exercise.builder().id(11L).name("Lunge").build();
        WorkoutProgramItem first = WorkoutProgramItem.builder()
            .id(1L).program(program).exercise(squat).sets(3).reps(12).orderIndex(0).build();
        WorkoutProgramItem second = WorkoutProgramItem.builder()
            .id(2L).program(program).exercise(lunge).sets(3).reps(10).orderIndex(1).build();
        WorkoutSession session = WorkoutSession.builder()
            .id(1L).user(user).program(program).currentItemIndex(0).targetScore(5.0).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findById(1L)).thenReturn(Optional.of(session));
        when(exerciseRepository.findById(10L)).thenReturn(Optional.of(squat));
        when(programItemRepository.findByProgramOrderByOrderIndex(program)).thenReturn(List.of(first, second));
        when(sessionRepository.save(any())).thenReturn(session);

        var request = new WorkoutNextRequest();
        request.setExerciseId(10L);
        request.setResult(WorkoutResult.GOOD);

        var response = workoutService.nextExercise("test@test.com", 1L, request);

        assertThat(response.isCompleted()).isFalse();
        assertThat(response.getExercise().getName()).isEqualTo("Lunge");
        assertThat(response.getSets()).isEqualTo(3);
        assertThat(response.getReps()).isEqualTo(10);
        verify(adaptiveService, never()).selectNextExercise(any(), any());
    }

    @Test
    void nextExercise_programMode_completesAfterLastItem() {
        User user = User.builder().id(1L).email("test@test.com").build();
        WorkoutProgram program = WorkoutProgram.builder().id(5L).build();
        Exercise squat = Exercise.builder().id(10L).build();
        WorkoutProgramItem only = WorkoutProgramItem.builder()
            .id(1L).program(program).exercise(squat).sets(3).reps(12).orderIndex(0).build();
        WorkoutSession session = WorkoutSession.builder()
            .id(1L).user(user).program(program).currentItemIndex(0).targetScore(5.0).build();

        when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(user));
        when(sessionRepository.findById(1L)).thenReturn(Optional.of(session));
        when(exerciseRepository.findById(10L)).thenReturn(Optional.of(squat));
        when(programItemRepository.findByProgramOrderByOrderIndex(program)).thenReturn(List.of(only));
        when(sessionRepository.save(any())).thenReturn(session);

        var request = new WorkoutNextRequest();
        request.setExerciseId(10L);
        request.setResult(WorkoutResult.GOOD);

        var response = workoutService.nextExercise("test@test.com", 1L, request);

        assertThat(response.isCompleted()).isTrue();
        assertThat(response.getExercise()).isNull();
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest#nextExercise_programMode_returnsNextItemInOrder+nextExercise_programMode_completesAfterLastItem`
Expected: FAIL — both sessions currently fall through to the adaptive branch, which throws (`durationMinutes` is null → NPE) or returns the wrong exercise

- [ ] **Step 3: Add the program-mode branch to `nextExercise`**

In `backend/src/main/java/com/gymposes/service/WorkoutService.java`, replace the `nextExercise` method:

```java
    public WorkoutNextResponse nextExercise(String userEmail, Long sessionId, WorkoutNextRequest request) {
        WorkoutSession session = sessionRepository.findById(sessionId).orElseThrow();
        User user = userRepository.findByEmail(userEmail).orElseThrow();
        Exercise current = exerciseRepository.findById(request.getExerciseId()).orElseThrow();

        sessionLogRepository.save(SessionLog.builder()
            .session(session).exercise(current)
            .result(request.getResult()).timestamp(LocalDateTime.now()).build());

        if (session.getProgram() != null) {
            return nextProgramExercise(session);
        }

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

    private WorkoutNextResponse nextProgramExercise(WorkoutSession session) {
        List<WorkoutProgramItem> items = programItemRepository.findByProgramOrderByOrderIndex(session.getProgram());
        int nextIndex = session.getCurrentItemIndex() + 1;
        session.setCurrentItemIndex(nextIndex);
        sessionRepository.save(session);

        if (nextIndex >= items.size()) {
            return WorkoutNextResponse.builder().completed(true).build();
        }

        WorkoutProgramItem next = items.get(nextIndex);
        return WorkoutNextResponse.builder()
            .exercise(toResponse(next.getExercise()))
            .completed(false)
            .sets(next.getSets())
            .reps(next.getReps())
            .build();
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd backend && mvn -q test -Dtest=WorkoutServiceTest`
Expected: `BUILD SUCCESS`, all 7 tests pass

- [ ] **Step 5: Run the full backend test suite**

Run: `cd backend && mvn -q test`
Expected: `BUILD SUCCESS`

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/gymposes/service/WorkoutService.java backend/src/test/java/com/gymposes/service/WorkoutServiceTest.java
git commit -m "feat(backend): branch nextExercise to walk program items in order"
```

---

## Task 6: Mobile Models — Exercise Catalog Fields & Program Models

**Files:**
- Modify: `mobile/lib/core/models/exercise.dart`
- Modify: `mobile/lib/core/models/workout_session.dart`
- Create: `mobile/lib/core/models/workout_program.dart`
- Create: `mobile/test/core/models/workout_program_test.dart`

**Interfaces:**
- Produces: `Exercise.muscleGroup: String?`, `Exercise.location: String?`, `WorkoutStartResponse.sets/reps: int?`, `WorkoutNextResponse.sets/reps: int?`, `ProgramItem{exerciseId, sets, reps, orderIndex}`, `WorkoutProgram{id, name, items: List<ProgramItem>}`

- [ ] **Step 1: Add `muscleGroup`/`location` to the `Exercise` model**

Replace the contents of `mobile/lib/core/models/exercise.dart`:

```dart
class Exercise {
  final int id;
  final String name;
  final String description;
  final int defaultReps;
  final String lottieAssetPath;
  final double difficultyScore;
  final String? muscleGroup;
  final String? location;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultReps,
    required this.lottieAssetPath,
    required this.difficultyScore,
    this.muscleGroup,
    this.location,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as int,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    defaultReps: (json['defaultReps'] as int?) ?? 12,
    lottieAssetPath: (json['lottieAssetPath'] as String?) ?? 'placeholder.json',
    difficultyScore: (json['difficultyScore'] as num?)?.toDouble() ?? 5.0,
    muscleGroup: json['muscleGroup'] as String?,
    location: json['location'] as String?,
  );
}
```

- [ ] **Step 2: Add `sets`/`reps` to `WorkoutStartResponse` and `WorkoutNextResponse`**

In `mobile/lib/core/models/workout_session.dart`, replace the `WorkoutStartResponse` and `WorkoutNextResponse` classes:

```dart
class WorkoutStartResponse {
  final int sessionId;
  final Exercise exercise;
  final int remainingSeconds;
  final int? sets;
  final int? reps;

  const WorkoutStartResponse({
    required this.sessionId,
    required this.exercise,
    required this.remainingSeconds,
    this.sets,
    this.reps,
  });

  factory WorkoutStartResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutStartResponse(
        sessionId: json['sessionId'] as int,
        exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        remainingSeconds: json['remainingSeconds'] as int,
        sets: json['sets'] as int?,
        reps: json['reps'] as int?,
      );
}

class WorkoutNextResponse {
  final Exercise? exercise;
  final bool completed;
  final int? sets;
  final int? reps;

  const WorkoutNextResponse({this.exercise, required this.completed, this.sets, this.reps});

  factory WorkoutNextResponse.fromJson(Map<String, dynamic> json) =>
      WorkoutNextResponse(
        exercise: json['exercise'] != null
            ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>)
            : null,
        completed: (json['completed'] as bool?) ?? false,
        sets: json['sets'] as int?,
        reps: json['reps'] as int?,
      );
}
```

Leave `WorkoutSummary` in that file unchanged.

- [ ] **Step 3: Write the failing test for the new `WorkoutProgram` model**

Create `mobile/test/core/models/workout_program_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymposesapp/core/models/workout_program.dart';

void main() {
  test('WorkoutProgram.fromJson parses id, name, and items', () {
    final json = {
      'id': 1,
      'name': 'Sabah Rutini',
      'items': [
        {'exerciseId': 10, 'sets': 3, 'reps': 12, 'orderIndex': 0},
        {'exerciseId': 11, 'sets': 3, 'reps': 10, 'orderIndex': 1},
      ],
    };

    final program = WorkoutProgram.fromJson(json);

    expect(program.id, 1);
    expect(program.name, 'Sabah Rutini');
    expect(program.items.length, 2);
    expect(program.items[0].exerciseId, 10);
    expect(program.items[0].sets, 3);
    expect(program.items[1].reps, 10);
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `cd mobile && flutter test test/core/models/workout_program_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'gymposesapp' in 'package:gymposesapp/core/models/workout_program.dart'` (file doesn't exist)

- [ ] **Step 5: Create the `WorkoutProgram` model**

Create `mobile/lib/core/models/workout_program.dart`:

```dart
class ProgramItem {
  final int exerciseId;
  final int sets;
  final int reps;
  final int orderIndex;

  const ProgramItem({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.orderIndex,
  });

  factory ProgramItem.fromJson(Map<String, dynamic> json) => ProgramItem(
    exerciseId: json['exerciseId'] as int,
    sets: json['sets'] as int,
    reps: json['reps'] as int,
    orderIndex: json['orderIndex'] as int,
  );
}

class WorkoutProgram {
  final int id;
  final String name;
  final List<ProgramItem> items;

  const WorkoutProgram({required this.id, required this.name, required this.items});

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
    id: json['id'] as int,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>)
        .map((i) => ProgramItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd mobile && flutter test test/core/models/workout_program_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Run the full mobile test suite to confirm no regression**

Run: `cd mobile && flutter test`
Expected: `All tests passed!` (existing `session_provider_test.dart`, `countdown_overlay_test.dart`, `good_bad_skip_bar_test.dart`, `widget_test.dart` still green)

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/core/models/exercise.dart mobile/lib/core/models/workout_session.dart mobile/lib/core/models/workout_program.dart mobile/test/core/models/workout_program_test.dart
git commit -m "feat(mobile): add program models and extend exercise/session models"
```

---

## Task 7: Exercise Catalog & Programs List Providers

**Files:**
- Create: `mobile/lib/features/programs/providers/exercise_catalog_provider.dart`
- Create: `mobile/lib/features/programs/providers/programs_provider.dart`

**Interfaces:**
- Consumes: `apiClientProvider` (existing, `mobile/lib/features/auth/providers/auth_provider.dart`), `Exercise.fromJson` / `WorkoutProgram.fromJson` (Task 6)
- Produces: `exerciseCatalogProvider: FutureProvider<List<Exercise>>`, `programsProvider: FutureProvider<List<WorkoutProgram>>`

No dedicated test — these are one-line Dio-fetch-and-map `FutureProvider`s with no branching logic, following the same untested pattern as the existing `authProvider`'s `register`/`login` (the codebase doesn't mock Dio; only pure state logic is unit tested, see `session_provider_test.dart`). Correctness is verified in Task 10 by running the app.

- [ ] **Step 1: Create `exerciseCatalogProvider`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise.dart';
import '../../auth/providers/auth_provider.dart';

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/exercises');
  return (res.data as List<dynamic>)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList();
});
```

- [ ] **Step 2: Create `programsProvider`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/workout_program.dart';
import '../../auth/providers/auth_provider.dart';

final programsProvider = FutureProvider<List<WorkoutProgram>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/programs');
  return (res.data as List<dynamic>)
      .map((p) => WorkoutProgram.fromJson(p as Map<String, dynamic>))
      .toList();
});
```

- [ ] **Step 3: Run `flutter analyze` to confirm both files compile cleanly**

Run: `cd mobile && flutter analyze lib/features/programs/providers`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/programs/providers/exercise_catalog_provider.dart mobile/lib/features/programs/providers/programs_provider.dart
git commit -m "feat(mobile): add exercise catalog and programs list providers"
```

---

## Task 8: Program Builder State & Notifier

**Files:**
- Create: `mobile/lib/features/programs/providers/program_builder_provider.dart`
- Create: `mobile/test/features/programs/program_builder_provider_test.dart`

**Interfaces:**
- Consumes: `Exercise` (Task 6), `apiClientProvider` (existing)
- Produces: `ProgramBuilderItem{exercise, sets, reps}`, `ProgramBuilderState{name, locationFilter, muscleGroupFilter, items, canSave}`, `programBuilderProvider: StateNotifierProvider<ProgramBuilderNotifier, ProgramBuilderState>`, `ProgramBuilderNotifier.{setName, setLocationFilter, setMuscleGroupFilter, addExercise, removeExercise, updateSets, updateReps, filteredExercises(List<Exercise>), save(): Future<int>, reset()}`

- [ ] **Step 1: Write the failing tests for the builder state/notifier**

Create `mobile/test/features/programs/program_builder_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymposesapp/core/models/exercise.dart';
import 'package:gymposesapp/features/programs/providers/program_builder_provider.dart';

Exercise _ex(int id, String name, {String location = 'BOTH', String muscleGroup = 'UPPER', int defaultReps = 12}) =>
    Exercise(
      id: id,
      name: name,
      description: '',
      defaultReps: defaultReps,
      lottieAssetPath: 'x.json',
      difficultyScore: 5.0,
      location: location,
      muscleGroup: muscleGroup,
    );

void main() {
  test('canSave is false with no name or items', () {
    const state = ProgramBuilderState();
    expect(state.canSave, false);
  });

  test('canSave is true once name is set and an item is added', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setName('Sabah Rutini');
    notifier.addExercise(_ex(1, 'Squat', defaultReps: 12));
    expect(notifier.state.canSave, true);
  });

  test('addExercise defaults to 3 sets and the exercise defaultReps', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat', defaultReps: 15));
    expect(notifier.state.items.single.sets, 3);
    expect(notifier.state.items.single.reps, 15);
  });

  test('addExercise ignores a duplicate exercise id', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(1, 'Squat'));
    expect(notifier.state.items.length, 1);
  });

  test('removeExercise removes the matching item', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(2, 'Lunge'));
    notifier.removeExercise(1);
    expect(notifier.state.items.length, 1);
    expect(notifier.state.items.single.exercise.id, 2);
  });

  test('updateSets and updateReps change only the matching item', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.addExercise(_ex(2, 'Lunge'));
    notifier.updateSets(1, 5);
    notifier.updateReps(2, 20);
    expect(notifier.state.items[0].sets, 5);
    expect(notifier.state.items[1].reps, 20);
  });

  test('filteredExercises filters by location, including BOTH', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setLocationFilter('HOME');
    final all = [
      _ex(1, 'Squat', location: 'BOTH'),
      _ex(2, 'Barfiks', location: 'GYM'),
      _ex(3, 'Dips', location: 'HOME'),
    ];
    final filtered = notifier.filteredExercises(all);
    expect(filtered.map((e) => e.id), containsAll([1, 3]));
    expect(filtered.map((e) => e.id), isNot(contains(2)));
  });

  test('filteredExercises filters by muscle group', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setMuscleGroupFilter('CORE');
    final all = [
      _ex(1, 'Squat', muscleGroup: 'LOWER'),
      _ex(2, 'Plank', muscleGroup: 'CORE'),
    ];
    final filtered = notifier.filteredExercises(all);
    expect(filtered.map((e) => e.id), [2]);
  });

  test('reset clears name and items', () {
    final notifier = ProgramBuilderNotifier(null);
    notifier.setName('Sabah Rutini');
    notifier.addExercise(_ex(1, 'Squat'));
    notifier.reset();
    expect(notifier.state.name, '');
    expect(notifier.state.items, isEmpty);
  });
}
```

Note: `ProgramBuilderNotifier(null)` — the constructor takes an `ApiClient?` so tests can exercise every method except `save()` (which needs a real `ApiClient`) without any mocking setup, matching the codebase's existing no-Dio-mocking convention.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd mobile && flutter test test/features/programs/program_builder_provider_test.dart`
Expected: FAIL — `program_builder_provider.dart` does not exist

- [ ] **Step 3: Implement `ProgramBuilderState` and `ProgramBuilderNotifier`**

Create `mobile/lib/features/programs/providers/program_builder_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/exercise.dart';
import '../../auth/providers/auth_provider.dart';

class ProgramBuilderItem {
  final Exercise exercise;
  final int sets;
  final int reps;

  const ProgramBuilderItem({required this.exercise, required this.sets, required this.reps});

  ProgramBuilderItem copyWith({int? sets, int? reps}) => ProgramBuilderItem(
        exercise: exercise,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
      );
}

class ProgramBuilderState {
  final String name;
  final String? locationFilter;
  final String? muscleGroupFilter;
  final List<ProgramBuilderItem> items;

  const ProgramBuilderState({
    this.name = '',
    this.locationFilter,
    this.muscleGroupFilter,
    this.items = const [],
  });

  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  ProgramBuilderState copyWith({
    String? name,
    String? locationFilter,
    String? muscleGroupFilter,
    List<ProgramBuilderItem>? items,
  }) =>
      ProgramBuilderState(
        name: name ?? this.name,
        locationFilter: locationFilter ?? this.locationFilter,
        muscleGroupFilter: muscleGroupFilter ?? this.muscleGroupFilter,
        items: items ?? this.items,
      );
}

final programBuilderProvider =
    StateNotifierProvider<ProgramBuilderNotifier, ProgramBuilderState>((ref) {
  return ProgramBuilderNotifier(ref.read(apiClientProvider));
});

class ProgramBuilderNotifier extends StateNotifier<ProgramBuilderState> {
  final ApiClient? _api;

  ProgramBuilderNotifier(this._api) : super(const ProgramBuilderState());

  void setName(String name) => state = state.copyWith(name: name);

  void setLocationFilter(String? location) => state = state.copyWith(locationFilter: location);

  void setMuscleGroupFilter(String? muscleGroup) => state = state.copyWith(muscleGroupFilter: muscleGroup);

  void addExercise(Exercise exercise) {
    if (state.items.any((i) => i.exercise.id == exercise.id)) return;
    state = state.copyWith(items: [
      ...state.items,
      ProgramBuilderItem(exercise: exercise, sets: 3, reps: exercise.defaultReps),
    ]);
  }

  void removeExercise(int exerciseId) {
    state = state.copyWith(items: state.items.where((i) => i.exercise.id != exerciseId).toList());
  }

  void updateSets(int exerciseId, int sets) {
    state = state.copyWith(
        items: state.items.map((i) => i.exercise.id == exerciseId ? i.copyWith(sets: sets) : i).toList());
  }

  void updateReps(int exerciseId, int reps) {
    state = state.copyWith(
        items: state.items.map((i) => i.exercise.id == exerciseId ? i.copyWith(reps: reps) : i).toList());
  }

  List<Exercise> filteredExercises(List<Exercise> all) {
    return all.where((e) {
      final locOk = state.locationFilter == null || e.location == state.locationFilter || e.location == 'BOTH';
      final mgOk = state.muscleGroupFilter == null || e.muscleGroup == state.muscleGroupFilter;
      return locOk && mgOk;
    }).toList();
  }

  Future<int> save() async {
    final items = state.items.asMap().entries.map((entry) => {
      'exerciseId': entry.value.exercise.id,
      'sets': entry.value.sets,
      'reps': entry.value.reps,
      'orderIndex': entry.key,
    }).toList();
    final res = await _api!.post('/programs', data: {'name': state.name, 'items': items});
    return res.data['id'] as int;
  }

  void reset() => state = const ProgramBuilderState();
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd mobile && flutter test test/features/programs/program_builder_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Run the full mobile test suite**

Run: `cd mobile && flutter test`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/programs/providers/program_builder_provider.dart mobile/test/features/programs/program_builder_provider_test.dart
git commit -m "feat(mobile): add program builder state and notifier"
```

---

## Task 9: Program-Mode Support in the Session Provider & Exercise Screen

**Files:**
- Modify: `mobile/lib/features/workout_session/providers/session_provider.dart`
- Modify: `mobile/lib/features/workout_session/screens/exercise_screen.dart`
- Modify: `mobile/test/features/workout_session/session_provider_test.dart`

**Interfaces:**
- Consumes: `WorkoutStartResponse.sets/reps` (Task 6)
- Produces: `SessionState.sets/reps: int?`, `SessionState.countUp: bool`, `SessionNotifier.startSessionFromProgram(int programId): Future<void>`

- [ ] **Step 1: Write the failing tests for the new `SessionState` fields**

Add to `mobile/test/features/workout_session/session_provider_test.dart`:

```dart
  test('SessionState default sets, reps, and countUp', () {
    const state = SessionState();
    expect(state.sets, null);
    expect(state.reps, null);
    expect(state.countUp, false);
  });

  test('SessionState copyWith sets sets/reps/countUp', () {
    const state = SessionState();
    final copy = state.copyWith(sets: 3, reps: 12, countUp: true);
    expect(copy.sets, 3);
    expect(copy.reps, 12);
    expect(copy.countUp, true);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd mobile && flutter test test/features/workout_session/session_provider_test.dart`
Expected: FAIL — `sets`/`reps`/`countUp` are not defined on `SessionState`

- [ ] **Step 3: Add `sets`, `reps`, `countUp` to `SessionState` and implement `startSessionFromProgram`**

Replace the full contents of `mobile/lib/features/workout_session/providers/session_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../auth/providers/auth_provider.dart';

class SessionState {
  final int? sessionId;
  final Exercise? currentExercise;
  final int remainingSeconds;
  final bool completed;
  final WorkoutSummary? summary;
  final bool isCountingDown;
  final int? sets;
  final int? reps;
  final bool countUp;

  const SessionState({
    this.sessionId,
    this.currentExercise,
    this.remainingSeconds = 0,
    this.completed = false,
    this.summary,
    this.isCountingDown = false,
    this.sets,
    this.reps,
    this.countUp = false,
  });

  SessionState copyWith({
    int? sessionId,
    Exercise? currentExercise,
    int? remainingSeconds,
    bool? completed,
    WorkoutSummary? summary,
    bool? isCountingDown,
    int? sets,
    int? reps,
    bool? countUp,
  }) =>
      SessionState(
        sessionId: sessionId ?? this.sessionId,
        currentExercise: currentExercise ?? this.currentExercise,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completed: completed ?? this.completed,
        summary: summary ?? this.summary,
        isCountingDown: isCountingDown ?? this.isCountingDown,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        countUp: countUp ?? this.countUp,
      );
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionState>>((ref) {
  return SessionNotifier(ref.read(apiClientProvider));
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionState>> {
  final ApiClient _api;

  SessionNotifier(this._api) : super(const AsyncValue.data(SessionState()));

  Future<void> startSession({
    required String location,
    required int durationMinutes,
    required String region,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/workout/start', data: {
        'location': location,
        'durationMinutes': durationMinutes,
        'region': region,
      });
      final response = WorkoutStartResponse.fromJson(
          res.data as Map<String, dynamic>);
      state = AsyncValue.data(SessionState(
        sessionId: response.sessionId,
        currentExercise: response.exercise,
        remainingSeconds: response.remainingSeconds,
        isCountingDown: true,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSessionFromProgram(int programId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/workout/start-from-program', data: {
        'programId': programId,
      });
      final response = WorkoutStartResponse.fromJson(
          res.data as Map<String, dynamic>);
      state = AsyncValue.data(SessionState(
        sessionId: response.sessionId,
        currentExercise: response.exercise,
        remainingSeconds: 0,
        isCountingDown: true,
        countUp: true,
        sets: response.sets,
        reps: response.reps,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void finishCountdown() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(isCountingDown: false));
    });
  }

  Future<void> submitResult(String result) async {
    final current = state.valueOrNull;
    if (current == null || current.sessionId == null) return;

    try {
      final res = await _api.post(
        '/workout/${current.sessionId}/next',
        data: {
          'exerciseId': current.currentExercise!.id,
          'result': result,
        },
      );
      final response = WorkoutNextResponse.fromJson(
          res.data as Map<String, dynamic>);

      if (response.completed) {
        await _completeSession(current.sessionId!);
      } else {
        state = AsyncValue.data(current.copyWith(
          currentExercise: response.exercise,
          completed: false,
          sets: response.sets,
          reps: response.reps,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endSession() async {
    final current = state.valueOrNull;
    if (current == null || current.sessionId == null) return;
    await _completeSession(current.sessionId!);
  }

  Future<void> _completeSession(int sessionId) async {
    final res = await _api.post('/workout/$sessionId/complete');
    final summary = WorkoutSummary.fromJson(res.data as Map<String, dynamic>);
    state = AsyncValue.data(SessionState(
      sessionId: sessionId,
      completed: true,
      summary: summary,
    ));
  }

  void tick() {
    state.whenData((s) {
      if (s.completed) return;
      if (s.countUp) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds + 1));
      } else if (s.remainingSeconds > 0) {
        state = AsyncValue.data(s.copyWith(remainingSeconds: s.remainingSeconds - 1));
      }
    });
  }

  void reset() => state = const AsyncValue.data(SessionState());
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd mobile && flutter test test/features/workout_session/session_provider_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Update the reps label in `ExerciseScreen`**

In `mobile/lib/features/workout_session/screens/exercise_screen.dart`, replace the `Text` widget inside the reps `Container` (currently `Text('${exercise.defaultReps} tekrar', ...)`):

```dart
                            child: Text(
                              session.sets != null && session.reps != null
                                  ? '${session.sets} set x ${session.reps} tekrar'
                                  : '${exercise.defaultReps} tekrar',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
```

- [ ] **Step 6: Run `flutter analyze` on the modified files**

Run: `cd mobile && flutter analyze lib/features/workout_session`
Expected: `No issues found!`

- [ ] **Step 7: Run the full mobile test suite**

Run: `cd mobile && flutter test`
Expected: `All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/workout_session/providers/session_provider.dart mobile/lib/features/workout_session/screens/exercise_screen.dart mobile/test/features/workout_session/session_provider_test.dart
git commit -m "feat(mobile): support program-mode sessions in SessionNotifier and ExerciseScreen"
```

---

## Task 10: Program List & Builder Screens, Routing, Entry Button

**Files:**
- Create: `mobile/lib/features/programs/screens/program_list_screen.dart`
- Create: `mobile/lib/features/programs/screens/program_builder_screen.dart`
- Modify: `mobile/lib/routing/app_router.dart`
- Modify: `mobile/lib/features/workout_setup/screens/location_screen.dart`

**Interfaces:**
- Consumes: `programsProvider`, `exerciseCatalogProvider` (Task 7), `programBuilderProvider` (Task 8), `sessionProvider.startSessionFromProgram` (Task 9)

- [ ] **Step 1: Create `ProgramListScreen`**

Create `mobile/lib/features/programs/screens/program_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../providers/programs_provider.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Programlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Program',
            onPressed: () => context.push('/programs/new'),
          ),
        ],
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('Henüz bir programın yok.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).startSessionFromProgram(program.id);
                      if (!context.mounted) return;
                      context.go('/session');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(program.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${program.items.length} egzersiz',
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Create `ProgramBuilderScreen`**

Create `mobile/lib/features/programs/screens/program_builder_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../workout_session/providers/session_provider.dart';
import '../providers/exercise_catalog_provider.dart';
import '../providers/program_builder_provider.dart';

class ProgramBuilderScreen extends ConsumerWidget {
  const ProgramBuilderScreen({super.key});

  static const _locations = [(null, 'Tümü'), ('HOME', 'Ev'), ('GYM', 'Salon')];
  static const _muscleGroups = [(null, 'Tümü'), ('UPPER', 'Üst'), ('LOWER', 'Alt'), ('CORE', 'Core')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(programBuilderProvider);
    final builderNotifier = ref.read(programBuilderProvider.notifier);
    final catalogAsync = ref.watch(exerciseCatalogProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Yeni Program')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Program adı'),
              onChanged: builderNotifier.setName,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              children: _locations.map((opt) {
                final (value, label) = opt;
                return ChoiceChip(
                  label: Text(label),
                  selected: builderState.locationFilter == value,
                  onSelected: (_) => builderNotifier.setLocationFilter(value),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              children: _muscleGroups.map((opt) {
                final (value, label) = opt;
                return ChoiceChip(
                  label: Text(label),
                  selected: builderState.muscleGroupFilter == value,
                  onSelected: (_) => builderNotifier.setMuscleGroupFilter(value),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: catalogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (all) {
                final filtered = builderNotifier.filteredExercises(all);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...filtered.map((exercise) => ListTile(
                          title: Text(exercise.name),
                          subtitle: Text('${exercise.defaultReps} tekrar (varsayılan)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                            onPressed: () => builderNotifier.addExercise(exercise),
                          ),
                        )),
                    if (builderState.items.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Seçilenler', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...builderState.items.map((item) => ListTile(
                            title: Text(item.exercise.name),
                            subtitle: Text('${item.sets} set x ${item.reps} tekrar'),
                            leading: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.bad),
                              onPressed: () => builderNotifier.removeExercise(item.exercise.id),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Stepper(
                                  value: item.sets,
                                  onChanged: (v) => builderNotifier.updateSets(item.exercise.id, v),
                                ),
                                const SizedBox(width: 8),
                                _Stepper(
                                  value: item.reps,
                                  onChanged: (v) => builderNotifier.updateReps(item.exercise.id, v),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: builderState.canSave
                  ? () async {
                      final programId = await builderNotifier.save();
                      builderNotifier.reset();
                      await ref.read(sessionProvider.notifier).startSessionFromProgram(programId);
                      if (!context.mounted) return;
                      context.go('/session');
                    }
                  : null,
              child: const Text('Kaydet ve Başlat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value'),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Wire the two new routes**

In `mobile/lib/routing/app_router.dart`, add two imports after the existing `history_screen.dart`/`profile_screen.dart` imports:

```dart
import '../features/programs/screens/program_list_screen.dart';
import '../features/programs/screens/program_builder_screen.dart';
```

And add two routes after the `/summary` route (before the `StatefulShellRoute`):

```dart
    GoRoute(path: '/programs',     builder: (_, __) => const ProgramListScreen()),
    GoRoute(path: '/programs/new', builder: (_, __) => const ProgramBuilderScreen()),
```

- [ ] **Step 4: Add the entry button to `LocationScreen`**

In `mobile/lib/features/workout_setup/screens/location_screen.dart`, replace the `appBar` line:

```dart
      appBar: AppBar(
        title: const Text('Nerede antrenman yapacaksın?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Programlarım',
            onPressed: () => context.push('/programs'),
          ),
        ],
      ),
```

- [ ] **Step 5: Run `flutter analyze` across the whole project**

Run: `cd mobile && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Run the full mobile test suite**

Run: `cd mobile && flutter test`
Expected: `All tests passed!`

- [ ] **Step 7: Manually verify the flow in Chrome**

Run: `cd mobile && flutter run -d chrome` (or hot-reload if already running)
1. Log in
2. Tap the "Programlarım" icon in the Antrenman tab's app bar
3. Tap "+", name a program, add 2-3 exercises with custom sets/reps, tap "Kaydet ve Başlat"
4. Confirm the countdown appears, then the exercise screen shows "X set x Y tekrar", and Good/Bad/Skip advances through the program in the order it was built, ending at the summary screen
5. Go back to "Programlarım" and confirm the saved program is listed and re-startable

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/programs/screens/program_list_screen.dart mobile/lib/features/programs/screens/program_builder_screen.dart mobile/lib/routing/app_router.dart mobile/lib/features/workout_setup/screens/location_screen.dart
git commit -m "feat(mobile): add program list/builder screens and entry point"
```

---

## Self-Review Notes

- **Spec coverage:** Data model (Task 1) → `GET /exercises` (Task 2) → program CRUD (Task 3) → start-from-program (Task 4) → fixed-order branching (Task 5) → mobile models (Task 6) → catalog/list providers (Task 7) → builder state (Task 8) → session/timer integration (Task 9) → screens/routing/entry button (Task 10). Every section of the 2026-08-01 design spec maps to a task.
- **Type consistency checked:** `ExerciseResponse.from`, `WorkoutProgramItemRepository.findByProgramOrderByOrderIndex`, `ProgramService.createProgram`/`listPrograms`, `WorkoutService.startSessionFromProgram`, `SessionState.sets/reps/countUp`, `ProgramBuilderNotifier.filteredExercises`/`save` are named identically everywhere they're referenced across tasks.
- **Out of scope (per design spec, unchanged):** editing/deleting/reordering saved programs, per-set tracking during a session, sharing programs between users.
