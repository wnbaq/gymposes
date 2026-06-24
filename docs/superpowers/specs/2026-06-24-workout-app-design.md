# GymPoses — Workout App Design Spec
**Tarih:** 2026-06-24  
**Teknoloji:** Flutter (Riverpod) + Spring Boot + PostgreSQL  
**Mimari:** Thin Client — tüm iş mantığı backend'de

---

## 1. Genel Bakış

Kullanıcı lokasyon (ev/spor salonu), süre ve beden bölgesi seçerek antrenman başlatır. Lottie animasyonlu egzersizleri tamamlar ve her egzersiz için Good/Bad/Skip değerlendirmesi yapar. Backend bu değerlendirmeleri ve kullanıcı skorunu birleştirerek sonraki egzersizi adaptif olarak seçer. Antrenman geçmişi backend'de saklanır.

---

## 2. Ekran Akışı

```
Giriş/Kayıt → Lokasyon → Süre → Bölge → [Egzersiz → Değerlendirme]* → Özet
```

| Screen | İsim | İçerik |
|--------|------|--------|
| 1 | Auth | Email/şifre giriş & kayıt |
| 2 | Lokasyon | Ev / Spor Salonu seçimi |
| 3 | Süre | 15 / 30 / 45 / 60 dakika |
| 4 | Bölge | Üst Vücut / Alt Vücut / Core (tekli seçim) |
| 5 | Egzersiz | Lottie animasyon + egzersiz adı + rep sayısı + oturum geri sayımı |
| 6 | Değerlendirme | Good / Bad / Skip butonları (egzersiz bitince alttan kayar) |
| 7 | Özet | Antrenman sonu özeti |

**Navigasyon:**
- Antrenman setup akışı (Screen 2-4): Stack navigation, geri gidilebilir
- Screen 5↔6 döngüsü: Süre dolana kadar backend'den egzersiz alır
- Uygulama geneli: Bottom tab — Antrenman / Geçmiş / Profil

---

## 3. Backend (Spring Boot)

### 3.1 Veri Modeli

```
User
  id, email, passwordHash, createdAt

Exercise
  id, name, description, muscleGroup (UPPER/LOWER/CORE),
  location (HOME/GYM/BOTH), difficultyScore (1-10),
  defaultReps (Int, varsayılan 12), lottieAssetPath

UserScore
  id, userId, exerciseId, score (Float — başlangıç: 5.0, kümülatif performans)

WorkoutSession
  id, userId, location, durationMinutes, region, targetScore (Float, başlangıç 5.0),
  startedAt, completedAt

SessionLog
  id, sessionId, exerciseId, result (GOOD/BAD/SKIP), timestamp
```

### 3.2 API Endpoint'leri

```
POST /auth/register
POST /auth/login                          → JWT token

POST /workout/start                       → { location, duration, region }
                                          ← { sessionId, exercise }
POST /workout/{sessionId}/next            → { exerciseId, result }
                                          ← { exercise } | { completed: true }
POST /workout/{sessionId}/complete        ← { summary }

GET  /history                             ← [ WorkoutSession ]
GET  /profile/stats                       ← { totalSessions, regionBreakdown, ... }
```

### 3.3 Adaptive Seçim Algoritması

`POST /workout/{sessionId}/next` çağrıldığında:

1. Mevcut sonucu `SessionLog`'a kaydet
2. `UserScore`'u güncelle:
   - GOOD  → score += 1.0
   - BAD   → score -= 0.5
   - SKIP  → score değişmez
3. Kullanıcının bölgedeki tüm egzersizlerini al
4. Her egzersiz için: `effectiveScore = difficultyScore × 0.6 + userScore × 0.4`
5. Hedef `effectiveScore`'a en yakın egzersizi seç (son oynanan hariç)
6. Hedef score: kullanıcının mevcut `targetScore` değeri (başlangıçta 5.0); GOOD → +0.5, BAD → -0.3, SKIP → değişmez. Bu değer WorkoutSession'da saklanır.

---

## 4. Flutter Uygulama Yapısı

```
lib/
├── core/
│   ├── api/          # Dio client, JWT interceptor
│   ├── models/       # Exercise, WorkoutSession, User, SessionLog
│   └── theme/        # Light & Clean tema (mor #6c63ff, turkuaz #48c9b0)
│
├── features/
│   ├── auth/
│   │   ├── screens/  # LoginScreen, RegisterScreen
│   │   └── provider/ # AuthNotifier
│   │
│   ├── workout_setup/
│   │   ├── screens/  # LocationScreen, DurationScreen, RegionScreen
│   │   └── provider/ # WorkoutSetupNotifier
│   │
│   ├── workout_session/
│   │   ├── screens/  # ExerciseScreen, EvaluationScreen
│   │   ├── widgets/  # LottiePlayer, CountdownTimer, GoodBadSkipBar
│   │   └── provider/ # SessionNotifier
│   │
│   ├── summary/
│   │   └── screens/  # WorkoutSummaryScreen
│   │
│   └── history/
│       └── screens/  # HistoryScreen, ProfileScreen
│
└── main.dart
```

**State Management:** Riverpod  
**HTTP:** Dio  
**Animasyon:** lottie paketi — dosyalar `assets/lottie/` klasöründe

---

## 5. UI Tarzı

**Tema:** Light & Clean  
**Renkler:**
- Primary: `#6c63ff` (mor)
- Secondary: `#48c9b0` (turkuaz)
- Background: `#ffffff`
- Surface: `#f5f5f5`

**Good/Bad/Skip butonları:**
- Good: Yeşil arka plan (`#e8f5e9`), koyu yeşil border
- Bad: Pembe arka plan (`#fce4ec`), pembe border
- Skip: Mor arka plan (`#ede7f6`), mor border

---

## 6. MVP Scope

### Dahil
- Email/şifre auth (JWT)
- Lokasyon → Süre → Bölge setup akışı
- Lottie animasyonlu egzersiz gösterimi + geri sayım
- Good / Bad / Skip değerlendirmesi
- Adaptive egzersiz seçimi (difficultyScore + userScore)
- Antrenman özeti ekranı
- Geçmiş antrenman listesi
- Profil stats (toplam antrenman, bölge dağılımı)
- Spring Boot REST API + PostgreSQL + seed data (egzersizler)

### Dışarıda (sonraki sürüm)
- Sosyal özellikler, skor tablosu
- Push notification / hatırlatıcı
- Admin paneli
- Offline mod
- Detaylı grafik/analytics
- Ses / müzik
- Video format alternatifi

---

## 7. Teknik Kararlar

| Karar | Seçim | Neden |
|-------|-------|-------|
| Mimari | Thin Client | Mantık tek yerde, iterate etmek kolay |
| State | Riverpod | Flutter'da modern, test edilebilir |
| HTTP | Dio | Interceptor desteği, JWT inject için |
| Animasyon | Lottie | Hafif, vektör tabanlı, ölçeklenebilir |
| DB | PostgreSQL | Üretim kalitesi, Spring Data JPA uyumu |
| Auth | JWT (Spring Security) | Stateless, mobil için ideal |
| Egzersiz verisi | Seed data (SQL/JSON) | MVP için admin paneli gerekmez |
