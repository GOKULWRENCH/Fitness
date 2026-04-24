import 'dart:convert';

import '../models/fitness_entry.dart';

String buildCsvExport(List<FitnessEntry> entries) {
  final buffer = StringBuffer()
    ..writeln(
      'date,weight_kg,calories,protein_g,meals,workout_duration_min,notes,waist_cm,neck_cm,height_cm,body_fat_percent,total_sets,workout_volume_kg,exercises',
    );

  for (final entry in entries) {
    buffer.writeln(
      <String>[
        entry.date.toIso8601String().split('T').first,
        _stringifyNumber(entry.weightKg),
        entry.calories?.toString() ?? '',
        _stringifyNumber(entry.proteinGrams),
        _escapeCsv(entry.meals.join(' | ')),
        entry.workoutDurationMinutes?.toString() ?? '',
        _escapeCsv(entry.notes),
        _stringifyNumber(entry.waistCm),
        _stringifyNumber(entry.neckCm),
        _stringifyNumber(entry.heightCm),
        _stringifyNumber(entry.bodyFatPercentage),
        entry.totalSets.toString(),
        _stringifyNumber(entry.workoutVolume),
        _escapeCsv(
          entry.exercises
              .map(
                (exercise) =>
                    '${exercise.workoutType}: ${exercise.exerciseName} '
                    '(${exercise.sets}x${exercise.reps} @ ${exercise.weightKg.toStringAsFixed(1)}kg)',
              )
              .join(' | '),
        ),
      ].join(','),
    );
  }

  return buffer.toString();
}

String buildJsonBackup(List<FitnessEntry> entries) {
  final payload = <String, dynamic>{
    'version': 1,
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
