import 'package:fitness/models/fitness_entry.dart';
import 'package:fitness/utils/fitness_calculations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal entry totals scale with quantity', () {
    const meal = MealEntry(
      name: 'Breakfast',
      foods: 'Egg',
      category: 'Breakfast',
      servingSize: '1 piece',
      quantity: 2,
      caloriesPerServing: 70,
      proteinPerServing: 6,
      carbsPerServing: 0.4,
      fatPerServing: 5,
    );

    expect(meal.calories, 140);
    expect(meal.proteinGrams, 12);
    expect(meal.carbsGrams, 0.8);
    expect(meal.fatGrams, 10);
  });

  test('weekly nutrition and workout summaries include custom metrics', () {
    final monday = FitnessEntry(
      id: '2026-04-20',
      date: DateTime(2026, 4, 20),
      calorieGoal: 2200,
      proteinGoalGrams: 160,
      meals: const [
        MealEntry(
          name: 'Breakfast',
          foods: 'Custom oats bowl',
          category: 'Breakfast',
          servingSize: '1 bowl',
          quantity: 1,
          caloriesPerServing: 500,
          proteinPerServing: 30,
        ),
      ],
      exercises: const [
        WorkoutExercise(
          workoutType: 'Chest',
          exerciseName: 'Bench Press',
          sets: 4,
          reps: 8,
          weightKg: 80,
          durationMinutes: 18,
          notes: 'Strong session',
        ),
      ],
    );

    final wednesday = FitnessEntry(
      id: '2026-04-22',
      date: DateTime(2026, 4, 22),
      meals: const [
        MealEntry(
          name: 'Snack',
          foods: 'Whey protein',
          category: 'Supplement',
          servingSize: '1 scoop',
          quantity: 2,
          caloriesPerServing: 120,
          proteinPerServing: 24,
        ),
      ],
      exercises: const [
        WorkoutExercise(
          workoutType: 'Cardio',
          exerciseName: 'Cycling',
          sets: 0,
          reps: 0,
          weightKg: 0,
          durationMinutes: 30,
          caloriesBurned: 280,
        ),
      ],
    );

    final friday = FitnessEntry(
      id: '2026-04-24',
      date: DateTime(2026, 4, 24),
      meals: const [],
      exercises: const [
        WorkoutExercise(
          workoutType: 'Rest Day',
          exerciseName: '',
          sets: 0,
          reps: 0,
          weightKg: 0,
          notes: 'Walking only',
        ),
      ],
    );

    final entries = [monday, wednesday, friday];

    final weeklyNutrition = buildWeeklyNutritionMetrics(
      entries,
      DateTime(2026, 4, 24),
    );
    final weeklyWorkout = buildWeeklyWorkoutSummary(
      entries,
      DateTime(2026, 4, 24),
    );

    expect(weeklyNutrition.averageCalories, 370);
    expect(weeklyNutrition.averageProtein, 39);
    expect(weeklyWorkout.workoutFrequency, 2);
    expect(weeklyWorkout.muscleGroups, ['Cardio', 'Chest']);
    expect(friday.hasWorkout, isFalse);
    expect(wednesday.cardioCaloriesBurned, 280);
  });
}
