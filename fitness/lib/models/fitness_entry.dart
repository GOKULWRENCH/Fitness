import '../data/fitness_masters.dart';

class MealEntry {
  const MealEntry({
    required this.name,
    required this.foods,
    this.category = '',
    this.foodCategory = '',
    this.servingSize = '',
    this.defaultServingSize,
    this.unit = '',
    this.quantity = 1,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
    this.source = '',
    this.isCustomFood = false,
    this.isRecentlyLogged = false,
    int? calories,
    double? proteinGrams,
  }) : _calories = calories,
       _proteinGrams = proteinGrams;

  final String name;
  final String foods;
  final String category;
  final String foodCategory;
  final String servingSize;
  final double? defaultServingSize;
  final String unit;
  final double quantity;
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;
  final String source;
  final bool isCustomFood;
  final bool isRecentlyLogged;
  final int? _calories;
  final double? _proteinGrams;

  String get mealLabel {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }

    final trimmedFoodCategory = effectiveFoodCategory;
    if (trimmedFoodCategory.isNotEmpty) {
      return trimmedFoodCategory;
    }

    return name.trim();
  }

  String get itemName => foods.trim();

  String get effectiveFoodCategory {
    final trimmed = foodCategory.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    final master = mealItemByName(itemName);
    if (master != null) {
      return master.category;
    }

    return '';
  }

  double get normalizedQuantity => quantity <= 0 ? 1 : quantity;

  double? get effectiveCaloriesPerServing =>
      caloriesPerServing ?? _calories?.toDouble();

  double? get effectiveProteinPerServing => proteinPerServing ?? _proteinGrams;

  String get displayServingSize {
    final trimmed = servingSize.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    final servingAmount = defaultServingSize;
    if (servingAmount != null && unit.trim().isNotEmpty) {
      return _buildServingSizeLabel(servingAmount, unit.trim());
    }

    final master = mealItemByName(itemName);
    return master?.servingSize ?? '';
  }

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
      calories != null ||
      proteinGrams != null ||
      carbsGrams != null ||
      fatGrams != null;

  String get summary {
    final quantityLabel = normalizedQuantity == 1
        ? ''
        : ' x ${_formatQuantity(normalizedQuantity)}';
    final servingLabel = displayServingSize.isNotEmpty
        ? ' (${displayServingSize})'
        : '';
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
    String? foodCategory,
    String? servingSize,
    double? defaultServingSize,
    bool clearDefaultServingSize = false,
    String? unit,
    double? quantity,
    double? caloriesPerServing,
    bool clearCaloriesPerServing = false,
    double? proteinPerServing,
    bool clearProteinPerServing = false,
    double? carbsPerServing,
    bool clearCarbsPerServing = false,
    double? fatPerServing,
    bool clearFatPerServing = false,
    String? source,
    bool? isCustomFood,
    bool? isRecentlyLogged,
    int? calories,
    bool clearCalories = false,
    double? proteinGrams,
    bool clearProteinGrams = false,
  }) {
    return MealEntry(
      name: name ?? this.name,
      foods: foods ?? this.foods,
      category: category ?? this.category,
      foodCategory: foodCategory ?? this.foodCategory,
      servingSize: servingSize ?? this.servingSize,
      defaultServingSize: clearDefaultServingSize
          ? null
          : (defaultServingSize ?? this.defaultServingSize),
      unit: unit ?? this.unit,
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
      source: source ?? this.source,
      isCustomFood: isCustomFood ?? this.isCustomFood,
      isRecentlyLogged: isRecentlyLogged ?? this.isRecentlyLogged,
      calories: clearCalories ? null : (calories ?? _calories),
      proteinGrams: clearProteinGrams ? null : (proteinGrams ?? _proteinGrams),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': mealLabel,
      'foods': itemName,
      'category': mealLabel,
      'foodCategory': effectiveFoodCategory,
      'itemName': itemName,
      'servingSize': displayServingSize,
      'defaultServingSize': defaultServingSize,
      'unit': unit,
      'quantity': normalizedQuantity,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'caloriesPerServing': effectiveCaloriesPerServing,
      'proteinPerServing': effectiveProteinPerServing,
      'carbsPerServing': carbsPerServing,
      'fatPerServing': fatPerServing,
      'source': source,
      'isCustomFood': isCustomFood,
      'isRecentlyLogged': isRecentlyLogged,
    };
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    String fallbackName = '',
  }) {
    final parsedFoods =
        (json['itemName'] as String?)?.trim() ??
        (json['foods'] as String?)?.trim() ??
        '';
    final master = mealItemByName(parsedFoods);
    final parsedName = (json['name'] as String?)?.trim() ?? fallbackName;
    final parsedCategory = (json['category'] as String?)?.trim() ?? parsedName;
    final parsedQuantity = _toDouble(json['quantity']) ?? 1;
    final safeQuantity = parsedQuantity <= 0 ? 1 : parsedQuantity;
    final totalCalories = _toDouble(json['calories']);
    final totalProtein = _toDouble(json['proteinGrams']);
    final totalCarbs = _toDouble(json['carbsGrams']);
    final totalFat = _toDouble(json['fatGrams']);
    final resolvedUnit =
        (json['unit'] as String?)?.trim() ?? master?.unit ?? '';
    final resolvedDefaultServing =
        _toDouble(json['defaultServingSize']) ?? master?.defaultServingSize;

    return MealEntry(
      name: parsedName,
      foods: master?.name ?? parsedFoods,
      category: parsedCategory,
      foodCategory:
          (json['foodCategory'] as String?)?.trim() ?? master?.category ?? '',
      servingSize:
          (json['servingSize'] as String?)?.trim() ??
          (resolvedDefaultServing != null && resolvedUnit.isNotEmpty
              ? _buildServingSizeLabel(resolvedDefaultServing, resolvedUnit)
              : (master?.servingSize ?? '')),
      defaultServingSize: resolvedDefaultServing,
      unit: resolvedUnit,
      quantity: safeQuantity,
      caloriesPerServing: _resolvePerServing(
        explicitPerServing: _toDouble(json['caloriesPerServing']),
        totalValue: totalCalories,
        quantity: safeQuantity,
        fallback: master?.calories,
      ),
      proteinPerServing: _resolvePerServing(
        explicitPerServing: _toDouble(json['proteinPerServing']),
        totalValue: totalProtein,
        quantity: safeQuantity,
        fallback: master?.protein,
      ),
      carbsPerServing: _resolvePerServing(
        explicitPerServing: _toDouble(json['carbsPerServing']),
        totalValue: totalCarbs,
        quantity: safeQuantity,
        fallback: master?.carbs,
      ),
      fatPerServing: _resolvePerServing(
        explicitPerServing: _toDouble(json['fatPerServing']),
        totalValue: totalFat,
        quantity: safeQuantity,
        fallback: master?.fat,
      ),
      source: (json['source'] as String?)?.trim() ?? master?.source ?? '',
      isCustomFood:
          json['isCustomFood'] == true ||
          (master == null && parsedFoods.trim().isNotEmpty),
      isRecentlyLogged:
          json['isRecentlyLogged'] == true || master?.isRecentlyLogged == true,
      calories: _toInt(json['calories']),
      proteinGrams: _toDouble(json['proteinGrams']),
    );
  }

  factory MealEntry.fromLegacyString(String value, int index) {
    final trimmed = value.trim();
    final master = mealItemByName(trimmed);
    return MealEntry(
      name: master?.category ?? 'Food ${index + 1}',
      foods: master?.name ?? trimmed,
      category: master?.category ?? 'Food',
      foodCategory: master?.category ?? '',
      servingSize: master?.servingSize ?? '',
      defaultServingSize: master?.defaultServingSize,
      unit: master?.unit ?? '',
      quantity: 1,
      caloriesPerServing: master?.calories,
      proteinPerServing: master?.protein,
      carbsPerServing: master?.carbs,
      fatPerServing: master?.fat,
      source: master?.source ?? 'Legacy log import',
      isCustomFood: master == null,
      isRecentlyLogged: true,
    );
  }
}

class WorkoutSetEntry {
  const WorkoutSetEntry({this.reps = 0, this.weightKg = 0});

  final int reps;
  final double weightKg;

  bool get isMeaningful => reps > 0 || weightKg > 0;

  String get summary {
    final repsLabel = reps > 0 ? '$reps reps' : '-- reps';
    final weightLabel = weightKg > 0
        ? '${_formatQuantity(weightKg)} kg'
        : '-- kg';
    return '$repsLabel x $weightLabel';
  }

  WorkoutSetEntry copyWith({int? reps, double? weightKg}) {
    return WorkoutSetEntry(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {'reps': reps, 'weightKg': weightKg};
  }

  factory WorkoutSetEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutSetEntry(
      reps: _toInt(json['reps']) ?? 0,
      weightKg: _toDouble(json['weightKg']) ?? 0,
    );
  }
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.workoutType,
    required this.exerciseName,
    this.sets = 0,
    this.reps = 0,
    this.weightKg = 0,
    this.performedSets = const <WorkoutSetEntry>[],
    this.durationMinutes = 0,
    this.caloriesBurned = 0,
    this.notes = '',
    this.primaryMuscle = '',
    this.secondaryMuscles = const <String>[],
    this.equipment = '',
    this.difficulty = '',
    this.exerciseType = '',
    this.instructions = '',
    this.source = '',
    this.isCustomExercise = false,
  });

  final String workoutType;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weightKg;
  final List<WorkoutSetEntry> performedSets;
  final int durationMinutes;
  final int caloriesBurned;
  final String notes;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String exerciseType;
  final String instructions;
  final String source;
  final bool isCustomExercise;

  bool get isCardio {
    final normalizedType = exerciseType.trim().toLowerCase();
    return normalizedType == 'cardio' ||
        normalizedType == 'hiit' ||
        isCardioWorkoutCategory(workoutType);
  }

  bool get isRestDay => workoutType.trim() == restDayWorkoutCategory;

  List<WorkoutSetEntry> get effectiveSets {
    final meaningfulSets = performedSets
        .where((setEntry) => setEntry.isMeaningful)
        .toList(growable: false);
    if (meaningfulSets.isNotEmpty) {
      return meaningfulSets;
    }

    if (sets <= 0 && reps <= 0 && weightKg <= 0) {
      return const <WorkoutSetEntry>[];
    }

    final count = sets > 0 ? sets : 1;
    return List<WorkoutSetEntry>.generate(
      count,
      (_) => WorkoutSetEntry(reps: reps, weightKg: weightKg),
      growable: false,
    );
  }

  bool get countsAsWorkout =>
      !isRestDay &&
      (exerciseName.trim().isNotEmpty ||
          effectiveSets.isNotEmpty ||
          durationMinutes > 0 ||
          caloriesBurned > 0 ||
          notes.trim().isNotEmpty);

  bool get isMeaningful => isRestDay
      ? workoutType.trim().isNotEmpty || notes.trim().isNotEmpty
      : countsAsWorkout;

  int get totalSets => countsAsWorkout ? effectiveSets.length : 0;

  int get totalReps => effectiveSets.fold(
    0,
    (running, setEntry) => running + setEntry.reps,
  );

  double get topWeightKg => effectiveSets.fold<double>(
    0,
    (running, setEntry) => setEntry.weightKg > running
        ? setEntry.weightKg
        : running,
  );

  double get volume => effectiveSets.fold<double>(
    0,
    (running, setEntry) => running + (setEntry.reps * setEntry.weightKg),
  );

  String get summary {
    final buffer = StringBuffer();
    final label = exerciseName.trim().isNotEmpty
        ? exerciseName.trim()
        : workoutType.trim();
    if (label.isNotEmpty) {
      buffer.write(label);
    }

    final details = <String>[];
    if (effectiveSets.isNotEmpty) {
      details.add(
        effectiveSets.map((setEntry) => setEntry.summary).join(' | '),
      );
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
    List<WorkoutSetEntry>? performedSets,
    int? durationMinutes,
    int? caloriesBurned,
    String? notes,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    String? difficulty,
    String? exerciseType,
    String? instructions,
    String? source,
    bool? isCustomExercise,
  }) {
    return WorkoutExercise(
      workoutType: workoutType ?? this.workoutType,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      performedSets: performedSets ?? this.performedSets,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      exerciseType: exerciseType ?? this.exerciseType,
      instructions: instructions ?? this.instructions,
      source: source ?? this.source,
      isCustomExercise: isCustomExercise ?? this.isCustomExercise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workoutType': workoutType,
      'exerciseName': exerciseName,
      'sets': totalSets,
      'reps': effectiveSets.isNotEmpty ? effectiveSets.first.reps : reps,
      'weightKg':
          effectiveSets.isNotEmpty ? effectiveSets.first.weightKg : weightKg,
      'performedSets': effectiveSets.map((setEntry) => setEntry.toJson()).toList(),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'difficulty': difficulty,
      'exerciseType': exerciseType,
      'instructions': instructions,
      'source': source,
      'isCustomExercise': isCustomExercise,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final parsedName = (json['exerciseName'] as String?)?.trim() ?? '';
    final master = exerciseByName(parsedName);
    final performedSetsJson =
        json['performedSets'] ?? json['loggedSets'] ?? json['setEntries'];
    final parsedSets = performedSetsJson is List
        ? performedSetsJson
              .whereType<Map>()
              .map(
                (setEntry) =>
                    WorkoutSetEntry.fromJson(Map<String, dynamic>.from(setEntry)),
              )
              .where((setEntry) => setEntry.isMeaningful)
              .toList(growable: false)
        : const <WorkoutSetEntry>[];
    final legacySets = _toInt(json['sets']) ?? 0;
    final legacyReps = _toInt(json['reps']) ?? 0;
    final legacyWeight = _toDouble(json['weightKg']) ?? 0;
    final resolvedWorkoutType =
        (json['workoutType'] as String?)?.trim() ??
        (json['muscleGroup'] as String?)?.trim() ??
        master?.muscleGroup ??
        '';

    return WorkoutExercise(
      workoutType: resolvedWorkoutType,
      exerciseName: master?.name ?? parsedName,
      sets: legacySets,
      reps: legacyReps,
      weightKg: legacyWeight,
      performedSets: parsedSets,
      durationMinutes: _toInt(json['durationMinutes']) ?? 0,
      caloriesBurned: _toInt(json['caloriesBurned']) ?? 0,
      notes: (json['notes'] as String?)?.trim() ?? '',
      primaryMuscle:
          (json['primaryMuscle'] as String?)?.trim() ??
          master?.primaryMuscle ??
          '',
      secondaryMuscles: _toStringList(json['secondaryMuscles']).isNotEmpty
          ? _toStringList(json['secondaryMuscles'])
          : master?.secondaryMuscles ?? const <String>[],
      equipment:
          (json['equipment'] as String?)?.trim() ?? master?.equipment ?? '',
      difficulty:
          (json['difficulty'] as String?)?.trim() ?? master?.difficulty ?? '',
      exerciseType:
          (json['exerciseType'] as String?)?.trim() ??
          master?.exerciseType ??
          '',
      instructions:
          (json['instructions'] as String?)?.trim() ??
          master?.instructions ??
          '',
      source: (json['source'] as String?)?.trim() ?? master?.source ?? '',
      isCustomExercise:
          json['isCustomExercise'] == true ||
          (master == null && parsedName.trim().isNotEmpty),
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
    this.carbsGrams,
    this.fatGrams,
    this.calorieGoal,
    this.proteinGoalGrams,
    this.workoutName = '',
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
  final double? carbsGrams;
  final double? fatGrams;
  final int? calorieGoal;
  final double? proteinGoalGrams;
  final List<MealEntry> meals;
  final List<WorkoutExercise> exercises;
  final String workoutName;
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
      if (type.isNotEmpty && type != restDayWorkoutCategory) {
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

  double? get totalCarbsGrams {
    final values = meals
        .map((meal) => meal.carbsGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isNotEmpty) {
      return _roundToSingleDecimal(
        values.fold<double>(0, (running, value) => running + value),
      );
    }
    return carbsGrams;
  }

  double? get totalFatGrams {
    final values = meals
        .map((meal) => meal.fatGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isNotEmpty) {
      return _roundToSingleDecimal(
        values.fold<double>(0, (running, value) => running + value),
      );
    }
    return fatGrams;
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
    double? carbsGrams,
    bool clearCarbsGrams = false,
    double? fatGrams,
    bool clearFatGrams = false,
    int? calorieGoal,
    bool clearCalorieGoal = false,
    double? proteinGoalGrams,
    bool clearProteinGoal = false,
    List<MealEntry>? meals,
    List<WorkoutExercise>? exercises,
    String? workoutName,
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
      carbsGrams: clearCarbsGrams ? null : (carbsGrams ?? this.carbsGrams),
      fatGrams: clearFatGrams ? null : (fatGrams ?? this.fatGrams),
      calorieGoal: clearCalorieGoal ? null : (calorieGoal ?? this.calorieGoal),
      proteinGoalGrams: clearProteinGoal
          ? null
          : (proteinGoalGrams ?? this.proteinGoalGrams),
      meals: meals ?? this.meals,
      exercises: exercises ?? this.exercises,
      workoutName: workoutName ?? this.workoutName,
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
      'carbsGrams': totalCarbsGrams,
      'fatGrams': totalFatGrams,
      'calorieGoal': calorieGoal,
      'proteinGoalGrams': proteinGoalGrams,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'workoutName': workoutName,
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
      carbsGrams: _toDouble(json['carbsGrams']),
      fatGrams: _toDouble(json['fatGrams']),
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
      workoutName: (json['workoutName'] as String?)?.trim() ?? '',
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

List<String> _toStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

double _roundToSingleDecimal(double value) {
  return double.parse(value.toStringAsFixed(1));
}

double? _resolvePerServing({
  required double? explicitPerServing,
  required double? totalValue,
  required double quantity,
  required double? fallback,
}) {
  if (explicitPerServing != null) {
    return explicitPerServing;
  }
  if (totalValue != null && quantity > 0) {
    return totalValue / quantity;
  }
  return fallback;
}

String _buildServingSizeLabel(double amount, String unit) {
  final amountLabel = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(1);
  final pluralized = amount == 1
      ? unit
      : (unit == 'piece' ? 'pieces' : unit);
  return '$amountLabel $pluralized';
}

String _formatQuantity(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
