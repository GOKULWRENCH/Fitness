import 'dart:convert';

import '../models/fitness_entry.dart';

String buildCsvExport(List<FitnessEntry> entries) {
  final buffer = StringBuffer()
    ..writeln(
      'date,weight_kg,calories,protein_g,carbs_g,fat_g,calorie_goal,protein_goal_g,calories_remaining,protein_remaining,meals,workout_name,workout_duration_min,cardio_calories_burned,total_exercises,notes,waist_cm,neck_cm,height_cm,body_fat_percent,total_sets,workout_volume_kg,muscle_groups,exercises',
    );

  for (final entry in entries) {
    final caloriesRemaining =
        entry.calorieGoal != null && entry.totalCalories != null
        ? entry.calorieGoal! - entry.totalCalories!
        : null;
    final proteinRemaining =
        entry.proteinGoalGrams != null && entry.totalProteinGrams != null
        ? entry.proteinGoalGrams! - entry.totalProteinGrams!
        : null;

    buffer.writeln(
      <String>[
        entry.date.toIso8601String().split('T').first,
        _stringifyNumber(entry.weightKg),
        entry.totalCalories?.toString() ?? '',
        _stringifyNumber(entry.totalProteinGrams),
        _stringifyNumber(entry.totalCarbsGrams),
        _stringifyNumber(entry.totalFatGrams),
        entry.calorieGoal?.toString() ?? '',
        _stringifyNumber(entry.proteinGoalGrams),
        caloriesRemaining?.toString() ?? '',
        _stringifyNumber(proteinRemaining),
        _escapeCsv(
          entry.meals
              .map(
                (meal) =>
                    '${meal.summary}'
                    '${meal.calories != null ? ' (${meal.calories} kcal' : ''}'
                    '${meal.proteinGrams != null ? ', ${_stringifyNumber(meal.proteinGrams)} g protein' : ''}'
                    '${meal.carbsGrams != null ? ', ${_stringifyNumber(meal.carbsGrams)} g carbs' : ''}'
                    '${meal.fatGrams != null ? ', ${_stringifyNumber(meal.fatGrams)} g fat' : ''}'
                    '${meal.calories != null || meal.proteinGrams != null || meal.carbsGrams != null || meal.fatGrams != null ? ')' : ''}',
              )
              .join(' | '),
        ),
        _escapeCsv(entry.workoutName),
        entry.totalWorkoutDurationMinutes.toString(),
        entry.cardioCaloriesBurned.toString(),
        entry.totalExercises.toString(),
        _escapeCsv(entry.notes),
        _stringifyNumber(entry.waistCm),
        _stringifyNumber(entry.neckCm),
        _stringifyNumber(entry.heightCm),
        _stringifyNumber(entry.bodyFatPercentage),
        entry.totalSets.toString(),
        _stringifyNumber(entry.workoutVolume),
        _escapeCsv(entry.muscleGroups.join(' | ')),
        _escapeCsv(
          entry.exercises.map((exercise) => exercise.summary).join(' | '),
        ),
      ].join(','),
    );
  }

  return buffer.toString();
}

String buildJsonBackup(List<FitnessEntry> entries) {
  final payload = <String, dynamic>{
    'version': 4,
    'exportedAt': DateTime.now().toIso8601String(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

List<FitnessEntry> parseJsonBackup(String rawJson) {
  final decoded = jsonDecode(rawJson);
  final entryMaps = switch (decoded) {
    List<dynamic> values => values,
    Map<dynamic, dynamic> values =>
      values['entries'] as List<dynamic>? ?? const [],
    _ => const <dynamic>[],
  };

  final entries =
      entryMaps
          .whereType<Map>()
          .map(
            (entry) => FitnessEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false)
        ..sort((left, right) => left.date.compareTo(right.date));

  return entries;
}

String _stringifyNumber(double? value) {
  if (value == null) {
    return '';
  }

  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return rounded;
}

String _escapeCsv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
