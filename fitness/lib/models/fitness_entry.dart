class MealEntry {
  const MealEntry({
    required this.name,
    required this.foods,
    this.category = '',
    this.servingSize = '',
    this.quantity = 1,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
    int? calories,
    double? proteinGrams,
  }) : _calories = calories,
       _proteinGrams = proteinGrams;

  final String name;
  final String foods;
  final String category;
  final String servingSize;
  final double quantity;
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;
  final int? _calories;
  final double? _proteinGrams;

  String get mealLabel {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }
    return name.trim();
  }

  String get itemName => foods.trim();

  double get normalizedQuantity => quantity <= 0 ? 1 : quantity;

  double? get effectiveCaloriesPerServing =>
      caloriesPerServing ?? _calories?.toDouble();

  double? get effectiveProteinPerServing => proteinPerServing ?? _proteinGrams;

  int? get calories {
    final perServing = effectiveCaloriesPerServing;
    if (perServing == null) {
      return _calories;
    }
    return (perServing * normalizedQuantity).round();
  }

  double? get proteinGrams {
    final perServing = effectiveProteinPerServing;
    if (perServing == null) {
      return _proteinGrams;
    }
    return _roundToSingleDecimal(perServing * normalizedQuantity);
  }

  double? get carbsGrams {
    if (carbsPerServing == null) {
      return null;
    }
    return _roundToSingleDecimal(carbsPerServing! * normalizedQuantity);
  }

  double? get fatGrams {
    if (fatPerServing == null) {
      return null;
    }
    return _roundToSingleDecimal(fatPerServing! * normalizedQuantity);
  }

  bool get isMeaningful =>
      itemName.isNotEmpty ||
      servingSize.trim().isNotEmpty ||
      calories != null ||
      proteinGrams != null ||
      carbsGrams != null ||
      fatGrams != null;

  String get summary {
    final quantityLabel = normalizedQuantity == 1
        ? ''
        : ' x ${_formatQuantity(normalizedQuantity)}';
    final servingLabel = servingSize.trim().isNotEmpty ? ' ($servingSize)' : '';
    final label = mealLabel;
    final item = itemName;

    if (label.isNotEmpty && item.isNotEmpty) {
      return '$label: $item$quantityLabel$servingLabel';
    }
    if (item.isNotEmpty) {
      return '$item$quantityLabel$servingLabel';
    }
    return label;
  }

  MealEntry copyWith({
    String? name,
    String? foods,
    String? category,
    String? servingSize,
    double? quantity,
    double? caloriesPerServing,
    bool clearCaloriesPerServing = false,
    double? proteinPerServing,
    bool clearProteinPerServing = false,
    double? carbsPerServing,
    bool clearCarbsPerServing = false,
    double? fatPerServing,
    bool clearFatPerServing = false,
    int? calories,
    bool clearCalories = false,
    double? proteinGrams,
    bool clearProteinGrams = false,
  }) {
    return MealEntry(
      name: name ?? this.name,
      foods: foods ?? this.foods,
      category: category ?? this.category,
      servingSize: servingSize ?? this.servingSize,
      quantity: quantity ?? normalizedQuantity,
      caloriesPerServing: clearCaloriesPerServing
          ? null
          : (caloriesPerServing ?? this.caloriesPerServing),
      proteinPerServing: clearProteinPerServing
          ? null
          : (proteinPerServing ?? this.proteinPerServing),
      carbsPerServing: clearCarbsPerServing
          ? null
          : (carbsPerServing ?? this.carbsPerServing),
      fatPerServing: clearFatPerServing
          ? null
          : (fatPerServing ?? this.fatPerServing),
      calories: clearCalories ? null : (calories ?? _calories),
      proteinGrams: clearProteinGrams ? null : (proteinGrams ?? _proteinGrams),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': mealLabel,
      'foods': itemName,
      'category': mealLabel,
      'itemName': itemName,
      'servingSize': servingSize,
      'quantity': normalizedQuantity,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'caloriesPerServing': effectiveCaloriesPerServing,
      'proteinPerServing': effectiveProteinPerServing,
      'carbsPerServing': carbsPerServing,
      'fatPerServing': fatPerServing,
    };
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    String fallbackName = '',
  }) {
    final parsedName = (json['name'] as String?)?.trim() ?? fallbackName;
    final parsedCategory = (json['category'] as String?)?.trim() ?? parsedName;
    final parsedFoods =
        (json['itemName'] as String?)?.trim() ??
        (json['foods'] as String?)?.trim() ??
        '';
    final parsedQuantity = _toDouble(json['quantity']) ?? 1;

    return MealEntry(
      name: parsedName,
      foods: parsedFoods,
      category: parsedCategory,
      servingSize: (json['servingSize'] as String?)?.trim() ?? '',
      quantity: parsedQuantity <= 0 ? 1 : parsedQuantity,
      caloriesPerServing:
          _toDouble(json['caloriesPerServing']) ?? _toDouble(json['calories']),
      proteinPerServing:
          _toDouble(json['proteinPerServing']) ??
          _toDouble(json['proteinGrams']),
      carbsPerServing:
          _toDouble(json['carbsPerServing']) ?? _toDouble(json['carbsGrams']),
      fatPerServing:
          _toDouble(json['fatPerServing']) ?? _toDouble(json['fatGrams']),
      calories: _toInt(json['calories']),
      proteinGrams: _toDouble(json['proteinGrams']),
    );
  }

  factory MealEntry.fromLegacyString(String value, int index) {
    return MealEntry(
      name: 'Meal ${index + 1}',
      foods: value.trim(),
      quantity: 1,
    );
  }
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.workoutType,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.durationMinutes = 0,
    this.caloriesBurned = 0,
    this.notes = '',
  });

  final String workoutType;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weightKg;
  final int durationMinutes;
  final int caloriesBurned;
  final String notes;

  bool get isCardio => workoutType.trim() == 'Cardio';

  bool get isRestDay => workoutType.trim() == 'Rest Day';

  bool get countsAsWorkout =>
      !isRestDay &&
      (exerciseName.trim().isNotEmpty ||
          sets > 0 ||
          reps > 0 ||
          weightKg > 0 ||
          durationMinutes > 0 ||
          caloriesBurned > 0 ||
          notes.trim().isNotEmpty);

  bool get isMeaningful => isRestDay
      ? workoutType.trim().isNotEmpty || notes.trim().isNotEmpty
      : countsAsWorkout;

  int get totalSets => countsAsWorkout ? sets : 0;

  double get volume =>
      countsAsWorkout && !isCardio ? sets * reps * weightKg : 0;

  String get summary {
    final buffer = StringBuffer();
    final label = workoutType.trim();
    if (label.isNotEmpty) {
      buffer.write(label);
    }
    final exercise = exerciseName.trim();
    if (exercise.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(': ');
      }
      buffer.write(exercise);
    }

    final details = <String>[];
    if (sets > 0 || reps > 0) {
      details.add('${sets}x$reps');
    }
    if (weightKg > 0) {
      details.add('@ ${weightKg.toStringAsFixed(1)}kg');
    }
    if (durationMinutes > 0) {
      details.add('$durationMinutes min');
    }
    if (caloriesBurned > 0) {
      details.add('$caloriesBurned kcal');
    }

    if (details.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write('(${details.join(', ')})');
    }

    final trimmedNotes = notes.trim();
    if (trimmedNotes.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' - ');
      }
      buffer.write(trimmedNotes);
    }

    return buffer.toString();
  }

  WorkoutExercise copyWith({
    String? workoutType,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weightKg,
    int? durationMinutes,
    int? caloriesBurned,
    String? notes,
  }) {
    return WorkoutExercise(
      workoutType: workoutType ?? this.workoutType,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workoutType': workoutType,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      workoutType: (json['workoutType'] as String?)?.trim() ?? '',
      exerciseName: (json['exerciseName'] as String?)?.trim() ?? '',
      sets: _toInt(json['sets']) ?? 0,
      reps: _toInt(json['reps']) ?? 0,
      weightKg: _toDouble(json['weightKg']) ?? 0,
      durationMinutes: _toInt(json['durationMinutes']) ?? 0,
      caloriesBurned: _toInt(json['caloriesBurned']) ?? 0,
      notes: (json['notes'] as String?)?.trim() ?? '',
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
    this.calorieGoal,
    this.proteinGoalGrams,
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
  final int? calorieGoal;
  final double? proteinGoalGrams;
  final List<MealEntry> meals;
  final List<WorkoutExercise> exercises;
  final int? workoutDurationMinutes;
  final String notes;
  final double? waistCm;
  final double? neckCm;
  final double? heightCm;
  final double? bodyFatPercentage;

  int get totalExercises =>
      exercises.where((exercise) => exercise.countsAsWorkout).length;

  int get totalSets =>
      exercises.fold(0, (running, exercise) => running + exercise.totalSets);

  double get workoutVolume =>
      exercises.fold(0, (running, exercise) => running + exercise.volume);

  int get totalWorkoutDurationMinutes {
    final manualDuration = workoutDurationMinutes ?? 0;
    if (manualDuration > 0) {
      return manualDuration;
    }

    return exercises.fold(
      0,
      (running, exercise) => running + exercise.durationMinutes,
    );
  }

  int get cardioCaloriesBurned {
    return exercises.fold(
      0,
      (running, exercise) =>
          running + (exercise.isCardio ? exercise.caloriesBurned : 0),
    );
  }

  List<String> get muscleGroups {
    final values = <String>{};
    for (final exercise in exercises) {
      final type = exercise.workoutType.trim();
      if (type.isNotEmpty && type != 'Rest Day') {
        values.add(type);
      }
    }

    final groups = values.toList(growable: false)..sort();
    return groups;
  }

  bool get hasWorkout =>
      totalWorkoutDurationMinutes > 0 ||
      exercises.any((exercise) => exercise.countsAsWorkout);

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
      return _roundToSingleDecimal(
        values.fold<double>(0, (running, value) => running + value),
      );
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
    int? calorieGoal,
    bool clearCalorieGoal = false,
    double? proteinGoalGrams,
    bool clearProteinGoal = false,
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
      calorieGoal: clearCalorieGoal ? null : (calorieGoal ?? this.calorieGoal),
      proteinGoalGrams: clearProteinGoal
          ? null
          : (proteinGoalGrams ?? this.proteinGoalGrams),
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
      'calorieGoal': calorieGoal,
      'proteinGoalGrams': proteinGoalGrams,
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
      calorieGoal: _toInt(json['calorieGoal']),
      proteinGoalGrams:
          _toDouble(json['proteinGoalGrams']) ?? _toDouble(json['proteinGoal']),
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

double _roundToSingleDecimal(double value) {
  return double.parse(value.toStringAsFixed(1));
}

String _formatQuantity(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
