class MealEntry {
  const MealEntry({
    required this.name,
    required this.foods,
    this.calories,
    this.proteinGrams,
  });

  final String name;
  final String foods;
  final int? calories;
  final double? proteinGrams;

  bool get isMeaningful =>
      name.trim().isNotEmpty ||
      foods.trim().isNotEmpty ||
      calories != null ||
      proteinGrams != null;

  String get summary {
    final trimmedName = name.trim();
    final trimmedFoods = foods.trim();
    if (trimmedName.isNotEmpty && trimmedFoods.isNotEmpty) {
      return '$trimmedName: $trimmedFoods';
    }
    return trimmedName.isNotEmpty ? trimmedName : trimmedFoods;
  }

  MealEntry copyWith({
    String? name,
    String? foods,
    int? calories,
    bool clearCalories = false,
    double? proteinGrams,
    bool clearProteinGrams = false,
  }) {
    return MealEntry(
      name: name ?? this.name,
      foods: foods ?? this.foods,
      calories: clearCalories ? null : (calories ?? this.calories),
      proteinGrams: clearProteinGrams
          ? null
          : (proteinGrams ?? this.proteinGrams),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'foods': foods,
      'calories': calories,
      'proteinGrams': proteinGrams,
    };
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    String fallbackName = '',
  }) {
    return MealEntry(
      name: (json['name'] as String?)?.trim() ?? fallbackName,
      foods: (json['foods'] as String?)?.trim() ?? '',
      calories: _toInt(json['calories']),
      proteinGrams: _toDouble(json['proteinGrams']),
    );
  }

  factory MealEntry.fromLegacyString(String value, int index) {
    return MealEntry(name: 'Meal ${index + 1}', foods: value.trim());
  }
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.workoutType,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });

  final String workoutType;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weightKg;

  bool get isMeaningful =>
      workoutType.trim().isNotEmpty ||
      exerciseName.trim().isNotEmpty ||
      sets > 0 ||
      reps > 0 ||
      weightKg > 0;

  int get totalSets => sets;

  double get volume => sets * reps * weightKg;

  WorkoutExercise copyWith({
    String? workoutType,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weightKg,
  }) {
    return WorkoutExercise(
      workoutType: workoutType ?? this.workoutType,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workoutType': workoutType,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      workoutType: (json['workoutType'] as String?)?.trim() ?? '',
      exerciseName: (json['exerciseName'] as String?)?.trim() ?? '',
      sets: _toInt(json['sets']) ?? 0,
      reps: _toInt(json['reps']) ?? 0,
      weightKg: _toDouble(json['weightKg']) ?? 0,
    );
  }
}

class FitnessEntry {
  const FitnessEntry({
    required this.id,
    required this.date,
    required this.meals,
    required this.exercises,
    this.weightKg,
    this.calories,
    this.proteinGrams,
    this.workoutDurationMinutes,
    this.notes = '',
    this.waistCm,
    this.neckCm,
    this.heightCm,
    this.bodyFatPercentage,
  });

  final String id;
  final DateTime date;
  final double? weightKg;
  final int? calories;
  final double? proteinGrams;
  final List<MealEntry> meals;
  final List<WorkoutExercise> exercises;
  final int? workoutDurationMinutes;
  final String notes;
  final double? waistCm;
  final double? neckCm;
  final double? heightCm;
  final double? bodyFatPercentage;

  int get totalSets =>
      exercises.fold(0, (running, exercise) => running + exercise.totalSets);

  double get workoutVolume =>
      exercises.fold(0, (running, exercise) => running + exercise.volume);

  bool get hasWorkout =>
      (workoutDurationMinutes ?? 0) > 0 ||
      exercises.any((exercise) => exercise.isMeaningful);

  int? get totalCalories {
    final values = meals
        .map((meal) => meal.calories)
        .whereType<int>()
        .toList(growable: false);
    if (values.isNotEmpty) {
      return values.fold<int>(0, (running, value) => running + value);
    }
    return calories;
  }

  double? get totalProteinGrams {
    final values = meals
        .map((meal) => meal.proteinGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isNotEmpty) {
      return values.fold<double>(0, (running, value) => running + value);
    }
    return proteinGrams;
  }

  String get mealsSummary => meals
      .map((meal) => meal.summary)
      .where((meal) => meal.isNotEmpty)
      .join(' | ');

  FitnessEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    bool clearWeightKg = false,
    int? calories,
    bool clearCalories = false,
    double? proteinGrams,
    bool clearProteinGrams = false,
    List<MealEntry>? meals,
    List<WorkoutExercise>? exercises,
    int? workoutDurationMinutes,
    bool clearWorkoutDuration = false,
    String? notes,
    double? waistCm,
    bool clearWaistCm = false,
    double? neckCm,
    bool clearNeckCm = false,
    double? heightCm,
    bool clearHeightCm = false,
    double? bodyFatPercentage,
    bool clearBodyFat = false,
  }) {
    return FitnessEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      calories: clearCalories ? null : (calories ?? this.calories),
      proteinGrams: clearProteinGrams
          ? null
          : (proteinGrams ?? this.proteinGrams),
      meals: meals ?? this.meals,
      exercises: exercises ?? this.exercises,
      workoutDurationMinutes: clearWorkoutDuration
          ? null
          : (workoutDurationMinutes ?? this.workoutDurationMinutes),
      notes: notes ?? this.notes,
      waistCm: clearWaistCm ? null : (waistCm ?? this.waistCm),
      neckCm: clearNeckCm ? null : (neckCm ?? this.neckCm),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      bodyFatPercentage: clearBodyFat
          ? null
          : (bodyFatPercentage ?? this.bodyFatPercentage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': normalizedDate(date).toIso8601String(),
      'weightKg': weightKg,
      'calories': totalCalories,
      'proteinGrams': totalProteinGrams,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'workoutDurationMinutes': workoutDurationMinutes,
      'notes': notes,
      'waistCm': waistCm,
      'neckCm': neckCm,
      'heightCm': heightCm,
      'bodyFatPercentage': bodyFatPercentage,
    };
  }

  factory FitnessEntry.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse(json['date'] as String? ?? '');
    final normalizedDate = parsedDate != null
        ? FitnessEntry.normalizedDate(parsedDate)
        : DateTime.now();
    final mealsJson = json['meals'];
    final exercisesJson = json['exercises'];

    return FitnessEntry(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : FitnessEntry.idForDate(normalizedDate),
      date: normalizedDate,
      weightKg: _toDouble(json['weightKg']),
      calories: _toInt(json['calories']),
      proteinGrams: _toDouble(json['proteinGrams']),
      meals: _parseMeals(mealsJson),
      exercises: exercisesJson is List
          ? exercisesJson
                .whereType<Map>()
                .map(
                  (exercise) => WorkoutExercise.fromJson(
                    Map<String, dynamic>.from(exercise),
                  ),
                )
                .where((exercise) => exercise.isMeaningful)
                .toList(growable: false)
          : const <WorkoutExercise>[],
      workoutDurationMinutes: _toInt(json['workoutDurationMinutes']),
      notes: (json['notes'] as String?)?.trim() ?? '',
      waistCm: _toDouble(json['waistCm']),
      neckCm: _toDouble(json['neckCm']),
      heightCm: _toDouble(json['heightCm']),
      bodyFatPercentage: _toDouble(json['bodyFatPercentage']),
    );
  }

  static DateTime normalizedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String idForDate(DateTime date) {
    final normalized = normalizedDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

List<MealEntry> _parseMeals(Object? mealsJson) {
  if (mealsJson is! List) {
    return const <MealEntry>[];
  }

  final meals = <MealEntry>[];
  for (var index = 0; index < mealsJson.length; index++) {
    final meal = mealsJson[index];
    if (meal is Map) {
      meals.add(
        MealEntry.fromJson(
          Map<String, dynamic>.from(meal),
          fallbackName: 'Meal ${index + 1}',
        ),
      );
      continue;
    }

    final value = meal?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      meals.add(MealEntry.fromLegacyString(value, index));
    }
  }

  return meals.where((meal) => meal.isMeaningful).toList(growable: false);
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
