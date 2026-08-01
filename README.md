# GymPoses

> An adaptive workout app that learns from your performance and selects the next exercise in real time.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-6DB33F?logo=springboot)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql)
![Riverpod](https://img.shields.io/badge/Riverpod-state_management-purple)
![JWT](https://img.shields.io/badge/Auth-JWT-black)
![Lottie](https://img.shields.io/badge/Animations-Lottie-00DDB4)

---

## What is GymPoses?

Most workout apps give you a fixed plan and call it "personalized." GymPoses is different — it adapts in real time based on how you actually perform.

You pick your location (home or gym), how long you have, and which muscle group to target. The app then guides you through Lottie-animated exercises with a countdown timer. After each exercise you tap **Good**, **Bad**, or **Skip**. The backend processes that feedback immediately and uses it to pick your next exercise — adjusting difficulty up or down based on your accumulated performance score.

The result: every session is slightly different, and the app gets better at matching your level the more you use it.

---

## Screenshots

> Replace these placeholders with actual screenshots once available.

| Auth | Location | Exercise |
|------|----------|----------|
| ![auth](docs/screenshots/auth.png) | ![location](docs/screenshots/location.png) | ![exercise](docs/screenshots/exercise.png) |

| Good/Bad/Skip | Summary | History |
|---------------|---------|---------|
| ![eval](docs/screenshots/evaluation.png) | ![summary](docs/screenshots/summary.png) | ![history](docs/screenshots/history.png) |

---

## Screen Flow

```
Login / Register
      │
      ▼
 Location (Home / Gym)
      │
      ▼
 Duration (15 / 30 / 45 / 60 min)
      │
      ▼
 Region (Upper Body / Lower Body / Core)
      │
      ▼
 3-2-1 Countdown (scale animation)
      │
      ▼
 ┌─────────────────────────┐
 │  Exercise (Lottie + timer) │◄──┐
 └─────────────────────────┘   │
      │                        │
      ▼                        │
 Evaluation (Good / Bad / Skip)│
      │ (time remaining?)      │
      └────────────────────────┘
      │ (time up, or stop button → confirm)
      ▼
 Workout Summary
```

Every exercise starts with a 3-2-1 countdown overlay (`CountdownOverlay`) before the timer runs. A stop button in the app bar lets the user end the session early, with a confirmation dialog before the session is finalized.

Bottom tab navigation: **Workout · History · Profile**

---

## Adaptive Algorithm

The core of GymPoses lives in `AdaptiveService`. When you submit a result, the backend:

1. Saves the result to `SessionLog`
2. Updates your `UserScore` for that exercise:
   - **Good** → `score += 1.0`
   - **Bad** → `score -= 0.5`
   - **Skip** → score unchanged
3. Fetches all exercises for your selected region and location
4. Computes an **effective score** for each:

```
effectiveScore = difficultyScore × 0.6 + userScore × 0.4
```

5. Selects the exercise whose `effectiveScore` is closest to your current `targetScore` (excluding the exercise you just did)
6. Updates `targetScore` on the session: Good → `+0.5`, Bad → `-0.3`, Skip → unchanged

This means the app progressively challenges you when you're doing well, and backs off when you're struggling — all without any manual configuration.

---

## Tech Stack

### Backend

| Technology | Role | Why |
|------------|------|-----|
| Spring Boot 3 | REST API framework | Production-grade, fast to iterate |
| Spring Security + JWT | Authentication | Stateless auth, ideal for mobile clients |
| Spring Data JPA | ORM | Type-safe queries, no boilerplate SQL |
| PostgreSQL | Database | Relational, production-quality |
| BCrypt | Password hashing | Industry standard |

### Mobile

| Technology | Role | Why |
|------------|------|-----|
| Flutter | Cross-platform UI | Single codebase for iOS & Android |
| Riverpod | State management | Modern, testable, no BuildContext dependency |
| Dio | HTTP client | Interceptor support for JWT injection |
| Lottie | Exercise animations | Lightweight vector animations, scalable |
| flutter_secure_storage | Token persistence | Encrypted storage on device |

---

## Project Structure

```
gymposes/
├── backend/
│   └── src/main/java/com/gymposes/
│       ├── config/          # SecurityConfig, CORS
│       ├── controller/      # AuthController, WorkoutController, UserController
│       ├── service/         # AuthService, WorkoutService, AdaptiveService, DataSeeder
│       ├── entity/          # User, Exercise, UserScore, WorkoutSession, SessionLog
│       ├── dto/             # Request/Response DTOs
│       ├── repository/      # Spring Data JPA repositories
│       ├── security/        # JwtService, JwtAuthFilter, UserDetailsServiceImpl
│       └── enums/           # MuscleGroup, ExerciseLocation, WorkoutResult
│
└── mobile/
    └── lib/
        ├── core/
        │   ├── api/         # Dio client with JWT interceptor
        │   ├── models/      # Exercise, WorkoutSession, UserStats
        │   ├── storage/     # SecureStorage wrapper
        │   └── theme/       # AppTheme (purple #6c63ff, teal #48c9b0)
        ├── features/
        │   ├── auth/        # Login & Register screens + AuthNotifier
        │   ├── workout_setup/  # Location, Duration, Region screens
        │   ├── workout_session/  # Exercise screen, timer, Good/Bad/Skip bar
        │   ├── summary/     # WorkoutSummaryScreen
        │   └── history/     # HistoryScreen, ProfileScreen
        ├── routing/         # GoRouter setup
        └── main.dart
```

---

## Getting Started

### Prerequisites

- Java 17+
- Maven 3.8+
- PostgreSQL 15+
- Flutter 3.x (`flutter doctor` should pass)

### 1 — Database

```sql
CREATE DATABASE gymposesdb;
```

The app uses `spring.jpa.hibernate.ddl-auto: create-drop` in dev mode — tables are created automatically on startup and seeded with exercises via `DataSeeder`.

### 2 — Backend

```bash
cd backend

# Set JWT secret (or use the default dev value in application.yml)
export JWT_SECRET=your_secret_here

mvn spring-boot:run
```

The API will be available at `http://localhost:8080`.

### 3 — Mobile

```bash
cd mobile

flutter pub get
```

Open [mobile/lib/core/api/api_client.dart](mobile/lib/core/api/api_client.dart) and set the base URL:

```dart
// Android emulator
static const baseUrl = 'http://10.0.2.2:8080';

// iOS simulator or real device on same network
static const baseUrl = 'http://localhost:8080';
```

Then run:

```bash
flutter run
```

---

## API Reference

All endpoints except `/auth/**` require a `Bearer <token>` header.

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/register` | No | Register with email + password |
| `POST` | `/auth/login` | No | Login, returns JWT token |
| `POST` | `/workout/start` | Yes | Start session `{ location, durationMinutes, region }` → `{ sessionId, exercise }` |
| `POST` | `/workout/{sessionId}/next` | Yes | Submit result + get next exercise `{ exerciseId, result }` → `{ exercise }` or `{ completed: true }` |
| `POST` | `/workout/{sessionId}/complete` | Yes | Finalize session → `{ summary }` |
| `GET` | `/history` | Yes | List past workout sessions |
| `GET` | `/profile/stats` | Yes | Total sessions, region breakdown, exercise counts |

---

## Roadmap

Features planned for future versions:

- [ ] Social features & leaderboard
- [ ] Push notifications / workout reminders
- [ ] Admin panel for exercise management
- [ ] Offline mode with local sync
- [ ] Detailed analytics & progress graphs
- [ ] Audio cues / background music
- [ ] Video format as alternative to Lottie

---

## License

MIT
