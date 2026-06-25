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
            ex("Diamond Şınav", "Elmas tutuş şınav", MuscleGroup.UPPER, ExerciseLocation.BOTH, 7.0, 8, "diamond_pushup.json"),
            // UPPER - HOME
            ex("Dips (Sandalye)", "Sandalyeyle triceps dips", MuscleGroup.UPPER, ExerciseLocation.HOME, 4.0, 12, "chair_dips.json"),
            // UPPER - GYM
            ex("Barfiks", "Ağırlık çekme hareketi", MuscleGroup.UPPER, ExerciseLocation.GYM, 6.0, 8, "pullup.json"),
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
