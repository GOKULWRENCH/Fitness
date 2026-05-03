const String cardioWorkoutCategory = 'Cardio';
const String hiitWorkoutCategory = 'HIIT';
const String mobilityWorkoutCategory = 'Mobility';
const String restDayWorkoutCategory = 'Rest Day';

String normalizeMasterName(String value) {
  final sanitized = value
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return sanitized;
}

String _canonicalFoodKey(String value) {
  final normalized = normalizeMasterName(value);
  return _foodAliasMap[normalized] ?? normalized;
}

String _canonicalExerciseKey(String value) {
  final normalized = normalizeMasterName(value);
  return _exerciseAliasMap[normalized] ?? normalized;
}

const Map<String, String> _foodAliasMap = <String, String>{
  'curd thayir': 'curd',
  'thayir': 'curd',
  'rice cooked': 'rice',
  'white rice': 'rice',
  'brown rice': 'rice',
  'whey protein powder': 'whey protein',
  'whey isolate': 'whey protein',
  'chapati': 'chapathi',
  'roti': 'chapathi',
  'egg whites': 'egg white',
  'mung beans': 'green gram',
  'moong dal': 'green gram',
  'cowpeas': 'vanpayar',
  'red cowpeas': 'vanpayar',
  'veg cutlet': 'veg cutlet',
  'curd rice': 'rice',
};

const Map<String, String> _exerciseAliasMap = <String, String>{
  'push up': 'push up',
  'push ups': 'push up',
  'pushup': 'push up',
  'pushups': 'push up',
  'bench press': 'bench press',
  'incline dumbbell press': 'incline bench press',
  'dumbbell bench press': 'dumbbell press',
  'barbell curl': 'biceps curl',
  'dumbbell curl': 'biceps curl',
  'overhead extension': 'overhead triceps extension',
  'triceps extension': 'overhead triceps extension',
  'calf raise': 'standing calf raise',
  'leg raises': 'leg raise',
  'crunches': 'crunch',
  'stair machine': 'stair master',
  'stairmaster': 'stair master',
  'treadmill': 'treadmill running',
  'battle ropes': 'battle rope',
  'burpee': 'burpees',
  'mountain climber': 'mountain climbers',
};

class MealItemMaster {
  const MealItemMaster({
    required this.name,
    required this.category,
    required this.defaultServingSize,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.isCustomFood = false,
    this.isRecentlyLogged = false,
  });

  final String name;
  final String category;
  final double defaultServingSize;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String source;
  final bool isCustomFood;
  final bool isRecentlyLogged;

  String get servingSize {
    final amount = defaultServingSize == defaultServingSize.roundToDouble()
        ? defaultServingSize.toStringAsFixed(0)
        : defaultServingSize.toStringAsFixed(1);
    return '$amount ${_unitLabel(unit, defaultServingSize)}';
  }

  MealItemMaster copyWith({
    String? name,
    String? category,
    double? defaultServingSize,
    String? unit,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? source,
    bool? isCustomFood,
    bool? isRecentlyLogged,
  }) {
    return MealItemMaster(
      name: name ?? this.name,
      category: category ?? this.category,
      defaultServingSize: defaultServingSize ?? this.defaultServingSize,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      source: source ?? this.source,
      isCustomFood: isCustomFood ?? this.isCustomFood,
      isRecentlyLogged: isRecentlyLogged ?? this.isRecentlyLogged,
    );
  }
}

const List<String> mealCategories = <String>[
  'Grains & Starches',
  'Protein',
  'Dairy',
  'Fruits',
  'Legumes',
  'Supplements',
  'Snacks',
  'Fast Food',
  'Prepared Meals',
];

const List<String> seededMyFoodNames = <String>[
  'Oats',
  'Milk',
  'Dates',
  'Peanut Butter',
  'Banana',
  'Egg',
  'Chicken Breast',
  'Fish',
  'Rice',
  'Chapathi',
  'Curd',
  'Sweet Potato',
  'Whey Protein',
  'Sausage',
  'Alfaham',
  'Mandi',
  'Veg Cutlet',
  'Momos',
  'Burger',
  'Vanpayar',
];

const List<String> seededRecentFoodNames = seededMyFoodNames;

const List<MealItemMaster> mealItemMasters = <MealItemMaster>[
  MealItemMaster(
    name: 'Rice',
    category: 'Grains & Starches',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 130,
    protein: 2.7,
    carbs: 28.0,
    fat: 0.3,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Chapathi',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 120,
    protein: 3.5,
    carbs: 18.0,
    fat: 3.0,
    source: 'USDA-style whole wheat flatbread reference',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Dosa',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 133,
    protein: 3.3,
    carbs: 20.7,
    fat: 3.7,
    source: 'USDA-style fermented rice and lentil crepe reference',
  ),
  MealItemMaster(
    name: 'Idli',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 58,
    protein: 2.0,
    carbs: 12.0,
    fat: 0.4,
    source: 'USDA-style steamed rice cake reference',
  ),
  MealItemMaster(
    name: 'Appam',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 120,
    protein: 2.3,
    carbs: 24.0,
    fat: 1.4,
    source: 'Composite estimate from rice and coconut batter',
  ),
  MealItemMaster(
    name: 'Puttu',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 230,
    protein: 4.7,
    carbs: 45.0,
    fat: 4.4,
    source: 'Composite estimate from rice flour and coconut',
  ),
  MealItemMaster(
    name: 'Parotta',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 330,
    protein: 6.0,
    carbs: 48.0,
    fat: 12.0,
    source: 'Composite estimate from layered flatbread ingredients',
  ),
  MealItemMaster(
    name: 'Upma',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 192,
    protein: 4.7,
    carbs: 30.0,
    fat: 5.5,
    source: 'Composite estimate from semolina upma ingredients',
  ),
  MealItemMaster(
    name: 'Poha',
    category: 'Grains & Starches',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 180,
    protein: 4.0,
    carbs: 33.0,
    fat: 4.0,
    source: 'Composite estimate from flattened rice recipe',
  ),
  MealItemMaster(
    name: 'Oats',
    category: 'Grains & Starches',
    defaultServingSize: 50,
    unit: 'gram',
    calories: 194,
    protein: 8.4,
    carbs: 33.1,
    fat: 3.6,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Sweet Potato',
    category: 'Grains & Starches',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 90,
    protein: 2.0,
    carbs: 21.0,
    fat: 0.2,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Potato',
    category: 'Grains & Starches',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 87,
    protein: 1.9,
    carbs: 20.0,
    fat: 0.1,
    source: 'USDA FoodData Central',
  ),
  MealItemMaster(
    name: 'Chicken Breast',
    category: 'Protein',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 165,
    protein: 31.0,
    carbs: 0.0,
    fat: 3.6,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Chicken Curry',
    category: 'Prepared Meals',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 230,
    protein: 24.0,
    carbs: 6.0,
    fat: 12.0,
    source: 'Composite estimate from chicken curry ingredients',
  ),
  MealItemMaster(
    name: 'Fish',
    category: 'Protein',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 120,
    protein: 22.0,
    carbs: 0.0,
    fat: 3.0,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Fish Fry',
    category: 'Prepared Meals',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 220,
    protein: 24.0,
    carbs: 4.0,
    fat: 11.0,
    source: 'Composite estimate from pan-fried fish ingredients',
  ),
  MealItemMaster(
    name: 'Fish Curry',
    category: 'Prepared Meals',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 180,
    protein: 22.0,
    carbs: 4.0,
    fat: 8.0,
    source: 'Composite estimate from fish curry ingredients',
  ),
  MealItemMaster(
    name: 'Egg',
    category: 'Protein',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 72,
    protein: 6.3,
    carbs: 0.4,
    fat: 4.8,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Egg White',
    category: 'Protein',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 17,
    protein: 3.6,
    carbs: 0.2,
    fat: 0.1,
    source: 'USDA FoodData Central',
  ),
  MealItemMaster(
    name: 'Paneer',
    category: 'Dairy',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 265,
    protein: 18.3,
    carbs: 1.2,
    fat: 20.8,
    source: 'USDA-style fresh cheese reference',
  ),
  MealItemMaster(
    name: 'Curd',
    category: 'Dairy',
    defaultServingSize: 100,
    unit: 'gram',
    calories: 61,
    protein: 3.5,
    carbs: 4.7,
    fat: 3.3,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Milk',
    category: 'Dairy',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 122,
    protein: 8.1,
    carbs: 11.7,
    fat: 4.8,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Whey Protein',
    category: 'Supplements',
    defaultServingSize: 1,
    unit: 'scoop',
    calories: 120,
    protein: 24.0,
    carbs: 3.0,
    fat: 1.5,
    source: 'Common whey isolate label average',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Peanut Butter',
    category: 'Supplements',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 94,
    protein: 3.6,
    carbs: 3.2,
    fat: 8.0,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Banana',
    category: 'Fruits',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 105,
    protein: 1.3,
    carbs: 27.0,
    fat: 0.4,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Dates',
    category: 'Fruits',
    defaultServingSize: 2,
    unit: 'piece',
    calories: 46,
    protein: 0.4,
    carbs: 12.5,
    fat: 0.1,
    source: 'USDA FoodData Central',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Dal',
    category: 'Legumes',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 198,
    protein: 12.6,
    carbs: 33.7,
    fat: 0.8,
    source: 'USDA-style cooked lentils reference',
  ),
  MealItemMaster(
    name: 'Chickpeas',
    category: 'Legumes',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 269,
    protein: 14.5,
    carbs: 45.0,
    fat: 4.2,
    source: 'USDA FoodData Central',
  ),
  MealItemMaster(
    name: 'Green Gram',
    category: 'Legumes',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 212,
    protein: 14.2,
    carbs: 38.7,
    fat: 0.8,
    source: 'USDA-style cooked mung beans reference',
  ),
  MealItemMaster(
    name: 'Vanpayar',
    category: 'Legumes',
    defaultServingSize: 1,
    unit: 'cup',
    calories: 227,
    protein: 15.0,
    carbs: 40.0,
    fat: 1.0,
    source: 'USDA-style cooked cowpeas reference',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Sausage',
    category: 'Protein',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 86,
    protein: 5.0,
    carbs: 1.0,
    fat: 7.0,
    source: 'USDA-style pork or chicken sausage average',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Alfaham',
    category: 'Prepared Meals',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 290,
    protein: 30.0,
    carbs: 3.0,
    fat: 18.0,
    source: 'Composite estimate from grilled spiced chicken',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Mandi',
    category: 'Prepared Meals',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 560,
    protein: 32.0,
    carbs: 58.0,
    fat: 20.0,
    source: 'Composite estimate from rice and roasted chicken serving',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Shawarma',
    category: 'Fast Food',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 390,
    protein: 21.0,
    carbs: 31.0,
    fat: 19.0,
    source: 'Composite estimate from chicken shawarma wrap ingredients',
  ),
  MealItemMaster(
    name: 'Burger',
    category: 'Fast Food',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 295,
    protein: 17.0,
    carbs: 30.0,
    fat: 13.0,
    source: 'USDA-style burger sandwich reference',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Momos',
    category: 'Fast Food',
    defaultServingSize: 1,
    unit: 'serving',
    calories: 250,
    protein: 9.0,
    carbs: 32.0,
    fat: 8.0,
    source: 'Composite estimate from steamed dumpling serving',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Veg Cutlet',
    category: 'Snacks',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 150,
    protein: 3.5,
    carbs: 17.0,
    fat: 7.0,
    source: 'Composite estimate from mixed vegetable cutlet',
    isRecentlyLogged: true,
  ),
  MealItemMaster(
    name: 'Cutlet',
    category: 'Snacks',
    defaultServingSize: 1,
    unit: 'piece',
    calories: 160,
    protein: 4.5,
    carbs: 17.0,
    fat: 8.0,
    source: 'Composite estimate from generic cutlet serving',
  ),
];

List<MealItemMaster> mealItemsForCategory(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) {
    return mealItemMasters;
  }

  return mealItemMasters
      .where((item) => item.category == trimmed)
      .toList(growable: false);
}

MealItemMaster? mealItemByName(String itemName) {
  final key = _canonicalFoodKey(itemName);
  if (key.isEmpty) {
    return null;
  }

  for (final item in mealItemMasters) {
    if (_canonicalFoodKey(item.name) == key) {
      return item;
    }
  }
  return null;
}

List<MealItemMaster> dedupeMealItems(Iterable<MealItemMaster> items) {
  final deduped = <String, MealItemMaster>{};
  for (final item in items) {
    final key = _canonicalFoodKey(item.name);
    final existing = deduped[key];
    if (existing == null || _preferMealItem(item, existing)) {
      deduped[key] = item;
    }
  }

  final values = deduped.values.toList(growable: false)
    ..sort((left, right) => left.name.compareTo(right.name));
  return values;
}

bool _preferMealItem(MealItemMaster candidate, MealItemMaster current) {
  if (candidate.isCustomFood != current.isCustomFood) {
    return !candidate.isCustomFood;
  }
  if (candidate.isRecentlyLogged != current.isRecentlyLogged) {
    return candidate.isRecentlyLogged;
  }
  if (candidate.source.isNotEmpty && current.source.isEmpty) {
    return true;
  }
  return false;
}

class ExerciseMaster {
  const ExerciseMaster({
    required this.name,
    required this.muscleGroup,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.exerciseType,
    required this.instructions,
    required this.source,
    this.isCustomExercise = false,
  });

  final String name;
  final String muscleGroup;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final String exerciseType;
  final String instructions;
  final String source;
  final bool isCustomExercise;

  ExerciseMaster copyWith({
    String? name,
    String? muscleGroup,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    String? difficulty,
    String? exerciseType,
    String? instructions,
    String? source,
    bool? isCustomExercise,
  }) {
    return ExerciseMaster(
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
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
}

const List<String> workoutCategories = <String>[
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Legs',
  'Abs',
  'Glutes',
  'Calves',
  'Forearms',
  cardioWorkoutCategory,
  hiitWorkoutCategory,
  mobilityWorkoutCategory,
  restDayWorkoutCategory,
];

const List<ExerciseMaster> exerciseMasters = <ExerciseMaster>[
  ExerciseMaster(
    name: 'Bench Press',
    muscleGroup: 'Chest',
    primaryMuscle: 'Pectorals',
    secondaryMuscles: <String>['Front Delts', 'Triceps'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Lower the bar to the mid chest, press up while keeping your upper back tight.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Incline Bench Press',
    muscleGroup: 'Chest',
    primaryMuscle: 'Upper Chest',
    secondaryMuscles: <String>['Front Delts', 'Triceps'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Use a slight incline, lower the bar under control, and press in a smooth arc.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Dumbbell Press',
    muscleGroup: 'Chest',
    primaryMuscle: 'Pectorals',
    secondaryMuscles: <String>['Front Delts', 'Triceps'],
    equipment: 'Dumbbells',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Press both dumbbells from chest level until arms are extended without losing shoulder position.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Push Up',
    muscleGroup: 'Chest',
    primaryMuscle: 'Pectorals',
    secondaryMuscles: <String>['Triceps', 'Core', 'Front Delts'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Keep a straight body line, lower until the chest nears the floor, then press away.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Chest Fly',
    muscleGroup: 'Chest',
    primaryMuscle: 'Pectorals',
    secondaryMuscles: <String>['Front Delts'],
    equipment: 'Dumbbells or Cable',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Maintain a soft elbow bend and bring the arms together with chest tension, not shoulder shrugging.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Lat Pulldown',
    muscleGroup: 'Back',
    primaryMuscle: 'Lats',
    secondaryMuscles: <String>['Biceps', 'Upper Back'],
    equipment: 'Cable Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Pull the bar toward your upper chest while driving elbows down and back.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Seated Row',
    muscleGroup: 'Back',
    primaryMuscle: 'Mid Back',
    secondaryMuscles: <String>['Lats', 'Biceps', 'Rear Delts'],
    equipment: 'Cable Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Row the handle toward the torso while keeping your chest lifted and shoulders down.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Barbell Row',
    muscleGroup: 'Back',
    primaryMuscle: 'Lats',
    secondaryMuscles: <String>['Mid Back', 'Biceps', 'Lower Back'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Hinge at the hips, brace your trunk, and row the bar to the lower ribs.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Deadlift',
    muscleGroup: 'Back',
    primaryMuscle: 'Posterior Chain',
    secondaryMuscles: <String>['Glutes', 'Hamstrings', 'Forearms'],
    equipment: 'Barbell',
    difficulty: 'Advanced',
    exerciseType: 'strength',
    instructions: 'Brace, push the floor away, and keep the bar close to your body through lockout.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Shoulder Press',
    muscleGroup: 'Shoulders',
    primaryMuscle: 'Deltoids',
    secondaryMuscles: <String>['Triceps', 'Upper Chest'],
    equipment: 'Dumbbells or Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Press overhead while keeping ribs stacked and wrists directly over elbows.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Lateral Raise',
    muscleGroup: 'Shoulders',
    primaryMuscle: 'Lateral Delts',
    secondaryMuscles: <String>['Upper Traps'],
    equipment: 'Dumbbells',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Lift the arms out to the sides with control and stop around shoulder height.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Rear Delt Fly',
    muscleGroup: 'Shoulders',
    primaryMuscle: 'Rear Delts',
    secondaryMuscles: <String>['Rhomboids', 'Mid Traps'],
    equipment: 'Dumbbells or Cable',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Hinge slightly and sweep the arms wide while squeezing the upper back.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Biceps Curl',
    muscleGroup: 'Biceps',
    primaryMuscle: 'Biceps',
    secondaryMuscles: <String>['Forearms'],
    equipment: 'Dumbbells or Barbell',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Curl without swinging and lower slowly to keep tension on the biceps.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Hammer Curl',
    muscleGroup: 'Biceps',
    primaryMuscle: 'Brachialis',
    secondaryMuscles: <String>['Biceps', 'Forearms'],
    equipment: 'Dumbbells',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Keep palms facing each other and curl with elbows tucked close to the torso.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Triceps Pushdown',
    muscleGroup: 'Triceps',
    primaryMuscle: 'Triceps',
    secondaryMuscles: <String>['Forearms'],
    equipment: 'Cable Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Pin the elbows by your sides and extend the arms fully on each rep.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Overhead Triceps Extension',
    muscleGroup: 'Triceps',
    primaryMuscle: 'Triceps',
    secondaryMuscles: <String>['Shoulders', 'Core'],
    equipment: 'Dumbbell or Cable',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Keep the elbows pointing up, stretch behind the head, and extend without flaring.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Squat',
    muscleGroup: 'Legs',
    primaryMuscle: 'Quadriceps',
    secondaryMuscles: <String>['Glutes', 'Core', 'Adductors'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Sit down between the hips, stay braced, and drive up through the full foot.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Leg Press',
    muscleGroup: 'Legs',
    primaryMuscle: 'Quadriceps',
    secondaryMuscles: <String>['Glutes', 'Hamstrings'],
    equipment: 'Leg Press Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Lower under control until the knees are comfortably bent, then press without locking out hard.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Leg Extension',
    muscleGroup: 'Legs',
    primaryMuscle: 'Quadriceps',
    secondaryMuscles: const <String>[],
    equipment: 'Leg Extension Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Extend the knees smoothly, pause briefly, and lower with control.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Leg Curl',
    muscleGroup: 'Legs',
    primaryMuscle: 'Hamstrings',
    secondaryMuscles: <String>['Calves'],
    equipment: 'Leg Curl Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Curl the pad toward the glutes while keeping hips down and movement controlled.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Lunges',
    muscleGroup: 'Legs',
    primaryMuscle: 'Quadriceps',
    secondaryMuscles: <String>['Glutes', 'Hamstrings', 'Core'],
    equipment: 'Bodyweight or Dumbbells',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Step into a stable split stance, lower with balance, and push back through the front leg.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Hip Thrust',
    muscleGroup: 'Glutes',
    primaryMuscle: 'Glutes',
    secondaryMuscles: <String>['Hamstrings', 'Core'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Drive hips up until fully extended while keeping the chin tucked and ribs down.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Glute Bridge',
    muscleGroup: 'Glutes',
    primaryMuscle: 'Glutes',
    secondaryMuscles: <String>['Hamstrings', 'Core'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Press through the heels and squeeze the glutes at the top without over-arching.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Standing Calf Raise',
    muscleGroup: 'Calves',
    primaryMuscle: 'Gastrocnemius',
    secondaryMuscles: <String>['Soleus'],
    equipment: 'Machine or Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Rise onto the balls of the feet, pause at the top, and lower through full range.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Seated Calf Raise',
    muscleGroup: 'Calves',
    primaryMuscle: 'Soleus',
    secondaryMuscles: <String>['Gastrocnemius'],
    equipment: 'Machine',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Keep knees bent, drive through the toes, and use a steady tempo.',
    source: 'wger Exercise Library',
  ),
  ExerciseMaster(
    name: 'Wrist Curl',
    muscleGroup: 'Forearms',
    primaryMuscle: 'Forearm Flexors',
    secondaryMuscles: const <String>[],
    equipment: 'Dumbbells or Barbell',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Rest the forearms, curl the wrists upward, and lower slowly.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Reverse Curl',
    muscleGroup: 'Forearms',
    primaryMuscle: 'Brachioradialis',
    secondaryMuscles: <String>['Biceps', 'Forearm Extensors'],
    equipment: 'Barbell or EZ Bar',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Use an overhand grip, keep elbows still, and curl without body swing.',
    source: 'ExRx Exercise Directory',
  ),
  ExerciseMaster(
    name: 'Plank',
    muscleGroup: 'Abs',
    primaryMuscle: 'Core',
    secondaryMuscles: <String>['Shoulders', 'Glutes'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Brace the trunk, squeeze glutes, and hold a straight line from shoulders to heels.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Crunch',
    muscleGroup: 'Abs',
    primaryMuscle: 'Rectus Abdominis',
    secondaryMuscles: <String>['Obliques'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'strength',
    instructions: 'Lift the shoulders with the abs while keeping the lower back controlled.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Leg Raise',
    muscleGroup: 'Abs',
    primaryMuscle: 'Lower Abs',
    secondaryMuscles: <String>['Hip Flexors'],
    equipment: 'Bodyweight or Captain Chair',
    difficulty: 'Intermediate',
    exerciseType: 'strength',
    instructions: 'Raise the legs without swinging and lower under control to keep the core engaged.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Stair Master',
    muscleGroup: cardioWorkoutCategory,
    primaryMuscle: 'Cardio',
    secondaryMuscles: <String>['Glutes', 'Quads', 'Calves'],
    equipment: 'Stair Climber',
    difficulty: 'Intermediate',
    exerciseType: 'cardio',
    instructions: 'Maintain a steady rhythm, stay upright, and use the rails lightly if needed.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Cycling',
    muscleGroup: cardioWorkoutCategory,
    primaryMuscle: 'Cardio',
    secondaryMuscles: <String>['Quads', 'Glutes', 'Calves'],
    equipment: 'Bike',
    difficulty: 'Beginner',
    exerciseType: 'cardio',
    instructions: 'Adjust resistance to target intensity and maintain a smooth cadence.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Treadmill Walking',
    muscleGroup: cardioWorkoutCategory,
    primaryMuscle: 'Cardio',
    secondaryMuscles: <String>['Calves', 'Glutes'],
    equipment: 'Treadmill',
    difficulty: 'Beginner',
    exerciseType: 'cardio',
    instructions: 'Walk tall with an easy arm swing and increase incline or pace as needed.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Treadmill Running',
    muscleGroup: cardioWorkoutCategory,
    primaryMuscle: 'Cardio',
    secondaryMuscles: <String>['Quads', 'Hamstrings', 'Calves'],
    equipment: 'Treadmill',
    difficulty: 'Intermediate',
    exerciseType: 'cardio',
    instructions: 'Run with quick relaxed strides and set pace or intervals to match your goal.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Battle Rope',
    muscleGroup: hiitWorkoutCategory,
    primaryMuscle: 'Full Body',
    secondaryMuscles: <String>['Shoulders', 'Core', 'Conditioning'],
    equipment: 'Heavy Ropes',
    difficulty: 'Advanced',
    exerciseType: 'HIIT',
    instructions: 'Keep a soft athletic stance and create fast rhythmic waves without losing posture.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Burpees',
    muscleGroup: hiitWorkoutCategory,
    primaryMuscle: 'Full Body',
    secondaryMuscles: <String>['Chest', 'Legs', 'Core'],
    equipment: 'Bodyweight',
    difficulty: 'Advanced',
    exerciseType: 'HIIT',
    instructions: 'Move smoothly from squat to plank to jump while keeping each rep controlled.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Mountain Climbers',
    muscleGroup: hiitWorkoutCategory,
    primaryMuscle: 'Core',
    secondaryMuscles: <String>['Shoulders', 'Hip Flexors', 'Conditioning'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    exerciseType: 'HIIT',
    instructions: 'Hold a strong plank and drive knees forward quickly without bouncing the hips.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Cat-Cow',
    muscleGroup: mobilityWorkoutCategory,
    primaryMuscle: 'Spine',
    secondaryMuscles: <String>['Shoulders', 'Hips'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'mobility',
    instructions: 'Move slowly between spinal flexion and extension while matching the breath.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Hip Flexor Stretch',
    muscleGroup: mobilityWorkoutCategory,
    primaryMuscle: 'Hip Flexors',
    secondaryMuscles: <String>['Glutes'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'stretching',
    instructions: 'Tuck the pelvis slightly and shift forward until you feel a front-of-hip stretch.',
    source: 'ACE Exercise Library',
  ),
  ExerciseMaster(
    name: 'Thoracic Rotation',
    muscleGroup: mobilityWorkoutCategory,
    primaryMuscle: 'Thoracic Spine',
    secondaryMuscles: <String>['Shoulders', 'Core'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    exerciseType: 'mobility',
    instructions: 'Rotate through the upper back while keeping the hips and lower back steady.',
    source: 'ACE Exercise Library',
  ),
];

List<String> exercisesForWorkoutCategory(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) {
    return exerciseMasters.map((item) => item.name).toList(growable: false);
  }

  return exerciseMasters
      .where((item) => item.muscleGroup == trimmed)
      .map((item) => item.name)
      .toList(growable: false);
}

ExerciseMaster? exerciseByName(String name) {
  final key = _canonicalExerciseKey(name);
  if (key.isEmpty) {
    return null;
  }

  for (final exercise in exerciseMasters) {
    if (_canonicalExerciseKey(exercise.name) == key) {
      return exercise;
    }
  }
  return null;
}

List<ExerciseMaster> dedupeExercises(Iterable<ExerciseMaster> items) {
  final deduped = <String, ExerciseMaster>{};
  for (final item in items) {
    final key = _canonicalExerciseKey(item.name);
    final existing = deduped[key];
    if (existing == null || _preferExercise(item, existing)) {
      deduped[key] = item;
    }
  }

  final values = deduped.values.toList(growable: false)
    ..sort((left, right) => left.name.compareTo(right.name));
  return values;
}

bool _preferExercise(ExerciseMaster candidate, ExerciseMaster current) {
  if (candidate.isCustomExercise != current.isCustomExercise) {
    return !candidate.isCustomExercise;
  }
  if (candidate.source.isNotEmpty && current.source.isEmpty) {
    return true;
  }
  return false;
}

bool isCardioWorkoutCategory(String category) {
  final trimmed = category.trim();
  return trimmed == cardioWorkoutCategory || trimmed == hiitWorkoutCategory;
}

bool isRestDayWorkoutCategory(String category) {
  return category.trim() == restDayWorkoutCategory;
}

String _unitLabel(String unit, double amount) {
  if (amount == 1) {
    return unit;
  }
  if (unit == 'piece') {
    return 'pieces';
  }
  return unit;
}
