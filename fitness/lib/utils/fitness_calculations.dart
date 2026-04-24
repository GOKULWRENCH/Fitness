import 'dart:math' as math;

import '../models/fitness_entry.dart';

class DashboardMetrics {
  const DashboardMetrics({
    this.currentWeight,
    this.startingWeight,
    this.totalWeightLoss,
    this.averageWeight,
    this.lowestWeight,
    this.highestWeight,
    this.currentBodyFat,
    this.bodyFatChange,
    this.waistChange,
    this.averageCalories,
    this.averageProtein,
    required this.totalWorkoutDays,
    required this.totalExercises,
    required this.totalSets,
    required this.totalWorkoutDurationMinutes,
    required this.cardioCaloriesBurned,
    required this.workoutVolume,
  });

  final double? currentWeight;
  final double? startingWeight;
  final double? totalWeightLoss;
  final double? averageWeight;
  final double? lowestWeight;
  final double? highestWeight;
  final double? currentBodyFat;
  final double? bodyFatChange;
  final double? waistChange;
  final double? averageCalories;
  final double? averageProtein;
  final int totalWorkoutDays;
  final int totalExercises;
  final int totalSets;
  final int totalWorkoutDurationMinutes;
  final int cardioCaloriesBurned;
  final double workoutVolume;
}

class WeeklyWorkoutBucket {
  const WeeklyWorkoutBucket({
    required this.weekStart,
    required this.workoutDays,
  });

  final DateTime weekStart;
  final int workoutDays;
}

class WeeklyNutritionMetrics {
  const WeeklyNutritionMetrics({this.averageCalories, this.averageProtein});

  final double? averageCalories;
  final double? averageProtein;
}

class WeeklyWorkoutSummary {
  const WeeklyWorkoutSummary({
    required this.workoutFrequency,
    required this.muscleGroups,
  });

  final int workoutFrequency;
  final List<String> muscleGroups;
}

double? calculateUsNavyBodyFat({
  required double waistCm,
  required double neckCm,
  required double heightCm,
}) {
  final waistMinusNeck = waistCm - neckCm;
  if (waistMinusNeck <= 0 || heightCm <= 0) {
    return null;
  }

  final bodyFat =
      495 /
          (1.0324 -
              0.19077 * _log10(waistMinusNeck) +
              0.15456 * _log10(heightCm)) -
      450;

  if (bodyFat.isNaN || bodyFat.isInfinite) {
    return null;
  }

  return double.parse(bodyFat.toStringAsFixed(1));
}

DashboardMetrics buildDashboardMetrics(List<FitnessEntry> entries) {
  if (entries.isEmpty) {
    return const DashboardMetrics(
      totalWorkoutDays: 0,
      totalExercises: 0,
      totalSets: 0,
      totalWorkoutDurationMinutes: 0,
      cardioCaloriesBurned: 0,
      workoutVolume: 0,
    );
  }

  final sortedEntries = List<FitnessEntry>.from(entries)
    ..sort((left, right) => left.date.compareTo(right.date));

  final weights = sortedEntries
      .map((entry) => entry.weightKg)
      .whereType<double>()
      .toList(growable: false);
  final calories = sortedEntries
      .map((entry) => entry.totalCalories?.toDouble())
      .whereType<double>()
      .toList(growable: false);
  final proteins = sortedEntries
      .map((entry) => entry.totalProteinGrams)
      .whereType<double>()
      .toList(growable: false);

  final currentWeight = _latestValue(sortedEntries, (entry) => entry.weightKg);
  final startingWeight = _firstValue(sortedEntries, (entry) => entry.weightKg);
  final currentBodyFat = _latestValue(
    sortedEntries,
    (entry) => entry.bodyFatPercentage,
  );
  final startingBodyFat = _firstValue(
    sortedEntries,
    (entry) => entry.bodyFatPercentage,
  );
  final currentWaist = _latestValue(sortedEntries, (entry) => entry.waistCm);
  final startingWaist = _firstValue(sortedEntries, (entry) => entry.waistCm);

  return DashboardMetrics(
    currentWeight: currentWeight,
    startingWeight: startingWeight,
    totalWeightLoss: currentWeight != null && startingWeight != null
        ? startingWeight - currentWeight
        : null,
    averageWeight: _average(weights),
    lowestWeight: weights.isEmpty ? null : weights.reduce(math.min),
    highestWeight: weights.isEmpty ? null : weights.reduce(math.max),
    currentBodyFat: currentBodyFat,
    bodyFatChange: currentBodyFat != null && startingBodyFat != null
        ? currentBodyFat - startingBodyFat
        : null,
    waistChange: currentWaist != null && startingWaist != null
        ? currentWaist - startingWaist
        : null,
    averageCalories: _average(calories),
    averageProtein: _average(proteins),
    totalWorkoutDays: sortedEntries.where((entry) => entry.hasWorkout).length,
    totalExercises: sortedEntries.fold(
      0,
      (running, entry) => running + entry.totalExercises,
    ),
    totalSets: sortedEntries.fold(
      0,
      (running, entry) => running + entry.totalSets,
    ),
    totalWorkoutDurationMinutes: sortedEntries.fold(
      0,
      (running, entry) => running + entry.totalWorkoutDurationMinutes,
    ),
    cardioCaloriesBurned: sortedEntries.fold(
      0,
      (running, entry) => running + entry.cardioCaloriesBurned,
    ),
    workoutVolume: sortedEntries.fold<double>(
      0,
      (running, entry) => running + entry.workoutVolume,
    ),
  );
}

WeeklyNutritionMetrics buildWeeklyNutritionMetrics(
  List<FitnessEntry> entries,
  DateTime anchorDate,
) {
  final weekEntries = entriesForWeek(entries, anchorDate);
  final calories = weekEntries
      .map((entry) => entry.totalCalories?.toDouble())
      .whereType<double>()
      .toList(growable: false);
  final proteins = weekEntries
      .map((entry) => entry.totalProteinGrams)
      .whereType<double>()
      .toList(growable: false);

  return WeeklyNutritionMetrics(
    averageCalories: _average(calories),
    averageProtein: _average(proteins),
  );
}

WeeklyWorkoutSummary buildWeeklyWorkoutSummary(
  List<FitnessEntry> entries,
  DateTime anchorDate,
) {
  final weekEntries = entriesForWeek(entries, anchorDate);
  final muscleGroups = <String>{};
  for (final entry in weekEntries) {
    muscleGroups.addAll(entry.muscleGroups);
  }

  final values = muscleGroups.toList(growable: false)..sort();
  return WeeklyWorkoutSummary(
    workoutFrequency: weekEntries.where((entry) => entry.hasWorkout).length,
    muscleGroups: values,
  );
}

List<WeeklyWorkoutBucket> buildWorkoutFrequency(List<FitnessEntry> entries) {
  if (entries.isEmpty) {
    return const <WeeklyWorkoutBucket>[];
  }

  final bucketMap = <DateTime, int>{};
  for (final entry in entries) {
    final bucketStart = startOfWeek(entry.date);
    bucketMap.update(
      bucketStart,
      (existing) => existing + (entry.hasWorkout ? 1 : 0),
      ifAbsent: () => entry.hasWorkout ? 1 : 0,
    );
  }

  final buckets =
      bucketMap.entries
          .map(
            (entry) => WeeklyWorkoutBucket(
              weekStart: entry.key,
              workoutDays: entry.value,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.weekStart.compareTo(right.weekStart));

  return buckets;
}

List<FitnessEntry> entriesForWeek(
  List<FitnessEntry> entries,
  DateTime anchorDate,
) {
  final weekStart = startOfWeek(anchorDate);
  final weekEnd = endOfWeek(anchorDate);

  return entries
      .where(
        (entry) =>
            !entry.date.isBefore(weekStart) && !entry.date.isAfter(weekEnd),
      )
      .toList(growable: false);
}

DateTime startOfWeek(DateTime date) {
  final normalized = FitnessEntry.normalizedDate(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  return startOfWeek(date).add(const Duration(days: 6));
}

double? _firstValue(
  List<FitnessEntry> entries,
  double? Function(FitnessEntry entry) selector,
) {
  for (final entry in entries) {
    final value = selector(entry);
    if (value != null) {
      return value;
    }
  }
  return null;
}

double? _latestValue(
  List<FitnessEntry> entries,
  double? Function(FitnessEntry entry) selector,
) {
  for (final entry in entries.reversed) {
    final value = selector(entry);
    if (value != null) {
      return value;
    }
  }
  return null;
}

double? _average(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  final total = values.fold<double>(0, (running, value) => running + value);
  return total / values.length;
}

double _log10(num value) => math.log(value) / math.ln10;
