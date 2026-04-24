const String cardioWorkoutCategory = 'Cardio';
const String restDayWorkoutCategory = 'Rest Day';

class MealItemMaster {
  const MealItemMaster({
    required this.name,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
  });

  final String name;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
}

const List<String> mealCategories = <String>[
  'Breakfast',
  'Lunch',
  'Snack',
  'Dinner',
  'Supplement',
];

const List<MealItemMaster> mealItemMasters = <MealItemMaster>[
  MealItemMaster(
    name: 'Egg',
    servingSize: '1 piece',
    calories: 70,
    protein: 6,
    carbs: 0.4,
    fat: 5,
    category: 'Breakfast',
  ),
  MealItemMaster(
    name: 'Oats',
    servingSize: '50 g',
    calories: 190,
    protein: 6,
    carbs: 33,
    fat: 3.5,
    category: 'Breakfast',
  ),
  MealItemMaster(
    name: 'Wheat bread',
    servingSize: '1 slice',
    calories: 70,
    protein: 3,
    carbs: 12,
    fat: 1,
    category: 'Breakfast',
  ),
  MealItemMaster(
    name: 'Chicken breast',
    servingSize: '100 g',
    calories: 165,
    protein: 31,
    carbs: 0,
    fat: 3.6,
    category: 'Lunch',
  ),
  MealItemMaster(
    name: 'Rice cooked',
    servingSize: '100 g',
    calories: 130,
    protein: 2.5,
    carbs: 28,
    fat: 0.3,
    category: 'Lunch',
  ),
  MealItemMaster(
    name: 'Fish',
    servingSize: '100 g',
    calories: 120,
    protein: 22,
    carbs: 0,
    fat: 3,
    category: 'Dinner',
  ),
  MealItemMaster(
    name: 'Soya chunks dry',
    servingSize: '50 g',
    calories: 170,
    protein: 26,
    carbs: 17,
    fat: 0.5,
    category: 'Dinner',
  ),
  MealItemMaster(
    name: 'Paneer',
    servingSize: '100 g',
    calories: 265,
    protein: 18,
    carbs: 1.2,
    fat: 20,
    category: 'Dinner',
  ),
  MealItemMaster(
    name: 'Curd',
    servingSize: '100 g',
    calories: 60,
    protein: 3.5,
    carbs: 4.7,
    fat: 3,
    category: 'Snack',
  ),
  MealItemMaster(
    name: 'Banana',
    servingSize: '1 medium',
    calories: 105,
    protein: 1,
    carbs: 27,
    fat: 0.3,
    category: 'Snack',
  ),
  MealItemMaster(
    name: 'Guava',
    servingSize: '1 medium',
    calories: 60,
    protein: 2,
    carbs: 13,
    fat: 1,
    category: 'Snack',
  ),
  MealItemMaster(
    name: 'Whey protein',
    servingSize: '1 scoop',
    calories: 120,
    protein: 24,
    carbs: 3,
    fat: 1.5,
    category: 'Supplement',
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
  final trimmed = itemName.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  for (final item in mealItemMasters) {
    if (item.name == trimmed) {
      return item;
    }
  }
  return null;
}

const List<String> workoutCategories = <String>[
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Legs',
  'Abs',
  cardioWorkoutCategory,
  'Full Body',
  restDayWorkoutCategory,
];

const Map<String, List<String>> workoutExercisesByCategory =
    <String, List<String>>{
      'Chest': <String>[
        'Bench Press',
        'Incline Dumbbell Press',
        'Chest Fly',
        'Push-ups',
        'Cable Crossover',
      ],
      'Back': <String>[
        'Lat Pulldown',
        'Seated Row',
        'Deadlift',
        'Barbell Row',
        'Pull-ups',
      ],
      'Shoulders': <String>[
        'Shoulder Press',
        'Lateral Raise',
        'Front Raise',
        'Rear Delt Fly',
        'Shrugs',
      ],
      'Biceps': <String>[
        'Barbell Curl',
        'Dumbbell Curl',
        'Hammer Curl',
        'Preacher Curl',
        'Cable Curl',
      ],
      'Triceps': <String>[
        'Triceps Pushdown',
        'Skull Crusher',
        'Overhead Extension',
        'Dips',
        'Close-Grip Bench Press',
      ],
      'Legs': <String>[
        'Squat',
        'Leg Press',
        'Lunges',
        'Leg Curl',
        'Leg Extension',
        'Calf Raise',
      ],
      'Abs': <String>[
        'Crunches',
        'Leg Raises',
        'Plank',
        'Russian Twists',
        'Mountain Climbers',
      ],
      cardioWorkoutCategory: <String>[
        'Treadmill',
        'Cycling',
        'Stair Machine',
        'Skipping',
        'HIIT',
      ],
      'Full Body': <String>[
        'Burpees',
        'Thrusters',
        'Kettlebell Swing',
        'Clean and Press',
        'Farmer\'s Carry',
      ],
      restDayWorkoutCategory: <String>[],
    };

List<String> exercisesForWorkoutCategory(String category) {
  return workoutExercisesByCategory[category] ?? const <String>[];
}

bool isCardioWorkoutCategory(String category) {
  return category.trim() == cardioWorkoutCategory;
}

bool isRestDayWorkoutCategory(String category) {
  return category.trim() == restDayWorkoutCategory;
}
