import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/fitness_masters.dart';
import '../models/fitness_entry.dart';
import '../services/fitness_repository.dart';
import '../utils/fitness_calculations.dart';

enum FoodMasterSection {
  allFoods,
  myFoods,
  recent,
  highProtein,
  carbs,
  fats,
  customFoods,
}

enum _HeaderAction { exportCsv, backupJson, restoreJson }

const String _customFoodValue = '__custom_food__';
const String _customExerciseValue = '__custom_exercise__';

class MasterLogHomePage extends StatefulWidget {
  const MasterLogHomePage({
    super.key,
    required this.repository,
    required this.onExportCsv,
    required this.onBackupJson,
    required this.onRestoreJson,
    required this.onOpenDashboard,
    required this.onShowMessage,
  });

  final FitnessRepository repository;
  final Future<void> Function() onExportCsv;
  final Future<void> Function() onBackupJson;
  final Future<void> Function() onRestoreJson;
  final VoidCallback onOpenDashboard;
  final void Function(String message) onShowMessage;

  @override
  State<MasterLogHomePage> createState() => _MasterLogHomePageState();
}

class _MasterLogHomePageState extends State<MasterLogHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _calorieGoalController = TextEditingController();
  final TextEditingController _proteinGoalController = TextEditingController();
  final TextEditingController _workoutNameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _foodSearchController = TextEditingController();
  final TextEditingController _exerciseSearchController =
      TextEditingController();

  final List<_FoodDraft> _foodDrafts = <_FoodDraft>[];
  final List<_ExerciseDraft> _exerciseDrafts = <_ExerciseDraft>[];

  DateTime _selectedDate = FitnessEntry.normalizedDate(DateTime.now());
  String? _editingEntryId;
  FoodMasterSection _foodSection = FoodMasterSection.allFoods;
  String _selectedFoodCategory = '';
  String _selectedExerciseCategory = '';
  String _selectedExerciseType = '';

  @override
  void initState() {
    super.initState();
    _attachPageListeners();
    _foodDrafts.add(_createFoodDraft());
    _exerciseDrafts.add(_createExerciseDraft());
    _resetForm(prefillHeight: true);
  }

  @override
  void didUpdateWidget(covariant MasterLogHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latestEntry = widget.repository.latestEntry;
    if (_editingEntryId == null &&
        _heightController.text.trim().isEmpty &&
        latestEntry?.heightCm != null) {
      _heightController.text = _formatControllerValue(
        latestEntry!.heightCm,
      );
    }
    if (_editingEntryId == null &&
        _calorieGoalController.text.trim().isEmpty &&
        latestEntry?.calorieGoal != null) {
      _calorieGoalController.text = latestEntry!.calorieGoal!.toString();
    }
    if (_editingEntryId == null &&
        _proteinGoalController.text.trim().isEmpty &&
        latestEntry?.proteinGoalGrams != null) {
      _proteinGoalController.text = _formatControllerValue(
        latestEntry!.proteinGoalGrams,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in <TextEditingController>[
      _weightController,
      _calorieGoalController,
      _proteinGoalController,
      _workoutNameController,
      _durationController,
      _notesController,
      _waistController,
      _neckController,
      _heightController,
      _foodSearchController,
      _exerciseSearchController,
    ]) {
      controller.dispose();
    }
    for (final draft in _foodDrafts) {
      draft.dispose();
    }
    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _attachPageListeners() {
    for (final controller in <TextEditingController>[
      _weightController,
      _calorieGoalController,
      _proteinGoalController,
      _workoutNameController,
      _durationController,
      _notesController,
      _waistController,
      _neckController,
      _heightController,
      _foodSearchController,
      _exerciseSearchController,
    ]) {
      controller.addListener(_triggerRebuild);
    }
  }

  void _registerFoodDraft(_FoodDraft draft) {
    for (final controller in draft.controllers) {
      controller.addListener(_triggerRebuild);
    }
  }

  void _registerExerciseDraft(_ExerciseDraft draft) {
    for (final controller in draft.controllers) {
      controller.addListener(_triggerRebuild);
    }
    for (final setDraft in draft.setDrafts) {
      for (final controller in setDraft.controllers) {
        controller.addListener(_triggerRebuild);
      }
    }
  }

  void _triggerRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _resetForm({bool prefillHeight = false}) {
    final latestEntry = widget.repository.latestEntry;
    _selectedDate = FitnessEntry.normalizedDate(DateTime.now());
    _editingEntryId = null;
    _selectedFoodCategory = '';
    _selectedExerciseCategory = '';
    _selectedExerciseType = '';
    _foodSection = FoodMasterSection.allFoods;

    _weightController.clear();
    _calorieGoalController.text = latestEntry?.calorieGoal?.toString() ?? '';
    _proteinGoalController.text = _formatControllerValue(
      latestEntry?.proteinGoalGrams,
    );
    _workoutNameController.clear();
    _durationController.clear();
    _notesController.clear();
    _waistController.clear();
    _neckController.clear();
    _heightController.text = prefillHeight && latestEntry?.heightCm != null
        ? _formatControllerValue(latestEntry!.heightCm)
        : '';
    _foodSearchController.clear();
    _exerciseSearchController.clear();

    for (final draft in _foodDrafts) {
      draft.dispose();
    }
    _foodDrafts
      ..clear()
      ..add(_createFoodDraft());

    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    _exerciseDrafts
      ..clear()
      ..add(_createExerciseDraft());

    if (mounted) {
      setState(() {});
    }
  }

  void _loadEntry(FitnessEntry entry) {
    _editingEntryId = entry.id;
    _selectedDate = entry.date;
    _weightController.text = _formatControllerValue(entry.weightKg);
    _calorieGoalController.text = entry.calorieGoal?.toString() ?? '';
    _proteinGoalController.text = _formatControllerValue(
      entry.proteinGoalGrams,
    );
    _workoutNameController.text = entry.workoutName;
    _durationController.text = entry.workoutDurationMinutes?.toString() ?? '';
    _notesController.text = entry.notes;
    _waistController.text = _formatControllerValue(entry.waistCm);
    _neckController.text = _formatControllerValue(entry.neckCm);
    _heightController.text = _formatControllerValue(entry.heightCm);

    for (final draft in _foodDrafts) {
      draft.dispose();
    }
    _foodDrafts
      ..clear()
      ..addAll(
        entry.meals.isEmpty
            ? <_FoodDraft>[_createFoodDraft()]
            : entry.meals
                  .map((meal) => _createFoodDraft(meal))
                  .toList(growable: false),
      );

    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    _exerciseDrafts
      ..clear()
      ..addAll(
        entry.exercises.isEmpty
            ? <_ExerciseDraft>[_createExerciseDraft()]
            : entry.exercises
                  .map((exercise) => _createExerciseDraft(exercise))
                  .toList(growable: false),
      );

    setState(() {});
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickEntryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = FitnessEntry.normalizedDate(pickedDate);
    });
  }

  Future<void> _saveEntry() async {
    final entry = _buildEntryFromDraft();
    if (entry == null) {
      widget.onShowMessage(
        'Add at least one food, workout, note, or metric before saving.',
      );
      return;
    }

    await widget.repository.saveEntry(entry, previousId: _editingEntryId);
    if (!mounted) {
      return;
    }

    _editingEntryId = entry.id;
    setState(() {});
    widget.onShowMessage(
      'Saved ${DateFormat('MMM d').format(entry.date)} with food and workout details.',
    );
  }

  Future<void> _deleteEntry(FitnessEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete entry?'),
          content: Text(
            'Remove the saved log for ${DateFormat('MMM d, yyyy').format(entry.date)} from local storage?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.repository.deleteEntry(entry.id);
    if (!mounted) {
      return;
    }

    if (_editingEntryId == entry.id) {
      _resetForm(prefillHeight: true);
    }
    widget.onShowMessage('Entry deleted from local storage.');
  }

  bool get _hasMeaningfulData {
    return _parseDouble(_weightController) != null ||
        _parseInt(_calorieGoalController) != null ||
        _parseDouble(_proteinGoalController) != null ||
        _foodDrafts.any((draft) => draft.toMeal().isMeaningful) ||
        _workoutNameController.text.trim().isNotEmpty ||
        _parseInt(_durationController) != null ||
        _notesController.text.trim().isNotEmpty ||
        _parseDouble(_waistController) != null ||
        _parseDouble(_neckController) != null ||
        _parseDouble(_heightController) != null ||
        _exerciseDrafts.any((draft) => draft.toExercise().isMeaningful);
  }

  FitnessEntry? _buildEntryFromDraft() {
    if (!_hasMeaningfulData) {
      return null;
    }

    final meals = _foodDrafts
        .map((draft) => draft.toMeal())
        .where((meal) => meal.isMeaningful)
        .toList(growable: false);
    final exercises = _exerciseDrafts
        .map((draft) => draft.toExercise())
        .where((exercise) => exercise.isMeaningful)
        .toList(growable: false);
    final waistCm = _parseDouble(_waistController);
    final neckCm = _parseDouble(_neckController);
    final heightCm = _parseDouble(_heightController);
    final bodyFat = waistCm != null && neckCm != null && heightCm != null
        ? calculateUsNavyBodyFat(
            waistCm: waistCm,
            neckCm: neckCm,
            heightCm: heightCm,
          )
        : null;

    return FitnessEntry(
      id: FitnessEntry.idForDate(_selectedDate),
      date: _selectedDate,
      weightKg: _parseDouble(_weightController),
      calorieGoal: _parseInt(_calorieGoalController),
      proteinGoalGrams: _parseDouble(_proteinGoalController),
      meals: meals,
      exercises: exercises,
      workoutName: _workoutNameController.text.trim(),
      workoutDurationMinutes: _parseInt(_durationController),
      notes: _notesController.text.trim(),
      waistCm: waistCm,
      neckCm: neckCm,
      heightCm: heightCm,
      bodyFatPercentage: bodyFat,
    );
  }

  _FoodDraft _createFoodDraft([MealEntry? meal]) {
    final draft = meal == null ? _FoodDraft() : _FoodDraft.fromMeal(meal);
    _registerFoodDraft(draft);
    return draft;
  }

  _ExerciseDraft _createExerciseDraft([WorkoutExercise? exercise]) {
    final draft = exercise == null
        ? _ExerciseDraft()
        : _ExerciseDraft.fromExercise(exercise);
    _registerExerciseDraft(draft);
    return draft;
  }

  void _addCustomFoodDraft() {
    setState(() {
      _foodDrafts.add(_createFoodDraft()..selectedFoodName = _customFoodValue);
    });
  }

  void _addCustomExerciseDraft() {
    setState(() {
      _exerciseDrafts.add(
        _createExerciseDraft()..selectedExerciseName = _customExerciseValue,
      );
    });
  }

  void _addFoodFromMaster(MealItemMaster item) {
    final key = normalizeMasterName(item.name);
    for (final draft in _foodDrafts) {
      if (!draft.isCustom &&
          normalizeMasterName(draft.resolvedName) == key) {
        draft.incrementQuantity();
        widget.onShowMessage('Increased ${item.name} quantity in today\'s log.');
        _triggerRebuild();
        return;
      }
    }

    setState(() {
      _foodDrafts.add(_createFoodDraft()..updateFoodSelection(item.name));
    });
  }

  void _addExerciseFromMaster(ExerciseMaster item) {
    final key = normalizeMasterName(item.name);
    for (final draft in _exerciseDrafts) {
      if (!draft.isCustom &&
          normalizeMasterName(draft.resolvedName) == key) {
        draft.addSet();
        widget.onShowMessage('Added another set row to ${item.name}.');
        _triggerRebuild();
        return;
      }
    }

    setState(() {
      _exerciseDrafts.add(
        _createExerciseDraft()..updateExerciseSelection(item.name),
      );
    });
  }

  double? get _derivedBodyFat {
    final waist = _parseDouble(_waistController);
    final neck = _parseDouble(_neckController);
    final height = _parseDouble(_heightController);
    if (waist == null || neck == null || height == null) {
      return null;
    }

    return calculateUsNavyBodyFat(
      waistCm: waist,
      neckCm: neck,
      heightCm: height,
    );
  }

  int? get _dailyMealCalories {
    final values = _foodDrafts
        .map((draft) => draft.toMeal().calories)
        .whereType<int>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.fold<int>(0, (running, value) => running + value);
  }

  double? get _dailyMealProtein {
    final values = _foodDrafts
        .map((draft) => draft.toMeal().proteinGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return double.parse(
      values
          .fold<double>(0, (running, value) => running + value)
          .toStringAsFixed(1),
    );
  }

  double? get _dailyMealCarbs {
    final values = _foodDrafts
        .map((draft) => draft.toMeal().carbsGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return double.parse(
      values
          .fold<double>(0, (running, value) => running + value)
          .toStringAsFixed(1),
    );
  }

  double? get _dailyMealFat {
    final values = _foodDrafts
        .map((draft) => draft.toMeal().fatGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return double.parse(
      values
          .fold<double>(0, (running, value) => running + value)
          .toStringAsFixed(1),
    );
  }

  List<MealItemMaster> get _allFoodItems {
    final fromHistory = widget.repository.entries.expand((entry) => entry.meals).map(
      (meal) => _foodMasterFromMeal(meal),
    );
    final fromDrafts = _foodDrafts
        .map((draft) => draft.asCustomMaster())
        .whereType<MealItemMaster>();

    return _orderedUniqueFoods(<MealItemMaster>[
      ...mealItemMasters,
      ...fromHistory,
      ...fromDrafts,
    ]);
  }

  List<MealItemMaster> get _recentFoodItems {
    final items = <MealItemMaster>[
      ..._seededFoodItems(seededRecentFoodNames),
    ];

    for (final entry in widget.repository.entries.reversed) {
      for (final meal in entry.meals.reversed) {
        items.add(_foodMasterFromMeal(meal).copyWith(isRecentlyLogged: true));
      }
    }

    return _orderedUniqueFoods(items, preserveOrder: true);
  }

  List<MealItemMaster> get _myFoodItems {
    final items = <MealItemMaster>[
      ..._seededFoodItems(seededMyFoodNames),
      ...widget.repository.entries.expand((entry) => entry.meals).map(
        _foodMasterFromMeal,
      ),
      ..._foodDrafts
          .map((draft) => draft.asCustomMaster())
          .whereType<MealItemMaster>(),
    ];

    return _orderedUniqueFoods(items, preserveOrder: true);
  }

  List<MealItemMaster> get _visibleFoodItems {
    final allFoods = _allFoodItems;
    final baseItems = switch (_foodSection) {
      FoodMasterSection.allFoods => allFoods,
      FoodMasterSection.myFoods => _myFoodItems,
      FoodMasterSection.recent => _recentFoodItems,
      FoodMasterSection.highProtein => allFoods
          .where((item) => item.protein >= 10)
          .toList(growable: false),
      FoodMasterSection.carbs => allFoods
          .where(
            (item) =>
                item.carbs >= 15 &&
                item.carbs >= item.protein &&
                item.carbs >= item.fat,
          )
          .toList(growable: false),
      FoodMasterSection.fats => allFoods
          .where((item) => item.fat >= 8)
          .toList(growable: false),
      FoodMasterSection.customFoods => allFoods
          .where((item) => item.isCustomFood)
          .toList(growable: false),
    };

    final query = normalizeMasterName(_foodSearchController.text);
    return baseItems.where((item) {
      final categoryMatches = _selectedFoodCategory.isEmpty
          ? true
          : item.category == _selectedFoodCategory;
      final queryMatches = query.isEmpty
          ? true
          : normalizeMasterName(item.name).contains(query);
      return categoryMatches && queryMatches;
    }).toList(growable: false);
  }

  List<ExerciseMaster> get _allExercises {
    final fromHistory = widget.repository.entries.expand((entry) => entry.exercises).map(
      _exerciseMasterFromHistory,
    );
    final fromDrafts = _exerciseDrafts
        .map((draft) => draft.asCustomMaster())
        .whereType<ExerciseMaster>();

    return _orderedUniqueExercises(<ExerciseMaster>[
      ...exerciseMasters,
      ...fromHistory,
      ...fromDrafts,
    ]);
  }

  List<ExerciseMaster> get _visibleExercises {
    final query = normalizeMasterName(_exerciseSearchController.text);
    return _allExercises.where((exercise) {
      final categoryMatches = _selectedExerciseCategory.isEmpty
          ? true
          : exercise.muscleGroup == _selectedExerciseCategory;
      final typeMatches = _selectedExerciseType.isEmpty
          ? true
          : exercise.exerciseType.toLowerCase() ==
              _selectedExerciseType.toLowerCase();
      final queryMatches = query.isEmpty
          ? true
          : normalizeMasterName(exercise.name).contains(query);
      return categoryMatches && typeMatches && queryMatches;
    }).toList(growable: false);
  }

  List<MealItemMaster> _seededFoodItems(List<String> names) {
    return names
        .map(mealItemByName)
        .whereType<MealItemMaster>()
        .toList(growable: false);
  }

  MealItemMaster _foodMasterFromMeal(MealEntry meal) {
    final master = mealItemByName(meal.itemName);
    if (master != null && !meal.isCustomFood) {
      return master.copyWith(isRecentlyLogged: true);
    }

    return MealItemMaster(
      name: meal.itemName,
      category: meal.effectiveFoodCategory.isNotEmpty
          ? meal.effectiveFoodCategory
          : 'Custom Foods',
      defaultServingSize: meal.defaultServingSize ?? 1,
      unit: meal.unit.trim().isEmpty ? 'serving' : meal.unit.trim(),
      calories: meal.effectiveCaloriesPerServing ?? 0,
      protein: meal.effectiveProteinPerServing ?? 0,
      carbs: meal.carbsPerServing ?? 0,
      fat: meal.fatPerServing ?? 0,
      source: meal.source.isNotEmpty ? meal.source : 'Logged custom food',
      isCustomFood: true,
      isRecentlyLogged: true,
    );
  }

  ExerciseMaster _exerciseMasterFromHistory(WorkoutExercise exercise) {
    final master = exerciseByName(exercise.exerciseName);
    if (master != null && !exercise.isCustomExercise) {
      return master;
    }

    return ExerciseMaster(
      name: exercise.exerciseName,
      muscleGroup: exercise.workoutType.isNotEmpty
          ? exercise.workoutType
          : 'Custom',
      primaryMuscle: exercise.primaryMuscle,
      secondaryMuscles: exercise.secondaryMuscles,
      equipment: exercise.equipment.isEmpty ? 'Custom' : exercise.equipment,
      difficulty: exercise.difficulty.isEmpty ? 'Custom' : exercise.difficulty,
      exerciseType: exercise.exerciseType.isEmpty
          ? 'strength'
          : exercise.exerciseType,
      instructions: exercise.instructions,
      source:
          exercise.source.isNotEmpty ? exercise.source : 'Logged custom exercise',
      isCustomExercise: true,
    );
  }

  List<MealItemMaster> _orderedUniqueFoods(
    Iterable<MealItemMaster> items, {
    bool preserveOrder = false,
  }) {
    final map = <String, MealItemMaster>{};
    for (final item in items) {
      final key = normalizeMasterName(item.name);
      if (key.isEmpty) {
        continue;
      }
      if (!map.containsKey(key)) {
        map[key] = item;
        continue;
      }

      final current = map[key]!;
      if (!item.isCustomFood && current.isCustomFood) {
        map[key] = item;
      }
    }

    final values = map.values.toList(growable: false);
    if (!preserveOrder) {
      values.sort((left, right) => left.name.compareTo(right.name));
    }
    return values;
  }

  List<ExerciseMaster> _orderedUniqueExercises(Iterable<ExerciseMaster> items) {
    final map = <String, ExerciseMaster>{};
    for (final item in items) {
      final key = normalizeMasterName(item.name);
      if (key.isEmpty) {
        continue;
      }
      map.putIfAbsent(key, () => item);
    }

    final values = map.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return values;
  }

  _ExerciseHistorySnapshot? _previousExerciseSnapshot(String exerciseName) {
    final key = normalizeMasterName(exerciseName);
    if (key.isEmpty) {
      return null;
    }

    final entries = widget.repository.entries.toList(growable: false).reversed;
    for (final entry in entries) {
      if (!entry.date.isBefore(_selectedDate)) {
        continue;
      }
      for (final exercise in entry.exercises) {
        if (normalizeMasterName(exercise.exerciseName) == key) {
          return _ExerciseHistorySnapshot(
            date: entry.date,
            topWeightKg: exercise.topWeightKg,
            volume: exercise.volume,
            totalSets: exercise.totalSets,
            summary: exercise.summary,
          );
        }
      }
    }
    return null;
  }

  Future<void> _handleHeaderAction(_HeaderAction action) async {
    switch (action) {
      case _HeaderAction.exportCsv:
        await widget.onExportCsv();
        return;
      case _HeaderAction.backupJson:
        await widget.onBackupJson();
        return;
      case _HeaderAction.restoreJson:
        await widget.onRestoreJson();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingEntry = widget.repository.entryForDate(_selectedDate);
    final draftEntry = _buildEntryFromDraft();
    final dailyMealCalories = _dailyMealCalories;
    final dailyMealProtein = _dailyMealProtein;
    final dailyMealCarbs = _dailyMealCarbs;
    final dailyMealFat = _dailyMealFat;
    final calorieGoal = _parseInt(_calorieGoalController);
    final proteinGoal = _parseDouble(_proteinGoalController);
    final caloriesRemaining =
        calorieGoal != null && dailyMealCalories != null
        ? calorieGoal - dailyMealCalories
        : null;
    final proteinRemaining =
        proteinGoal != null && dailyMealProtein != null
        ? double.parse((proteinGoal - dailyMealProtein).toStringAsFixed(1))
        : null;
    final recentEntries = widget.repository.entries.reversed.take(8).toList();
    final workoutHistory = widget.repository.entries
        .where((entry) => entry.hasWorkout)
        .toList(growable: false)
        .reversed
        .take(8)
        .toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MasterHeader(
              selectedDate: _selectedDate,
              onPickDate: _pickEntryDate,
              onOpenDashboard: widget.onOpenDashboard,
              onHeaderActionSelected: _handleHeaderAction,
              isEditing: _editingEntryId != null,
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Daily Snapshot',
              subtitle:
                  'Track today fast, keep your old data safe, and see totals update instantly as you log.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricChip(
                        label: 'Calories',
                        value: dailyMealCalories != null
                            ? '$dailyMealCalories kcal'
                            : '--',
                        icon: Icons.local_fire_department_outlined,
                      ),
                      _MetricChip(
                        label: 'Protein',
                        value: dailyMealProtein != null
                            ? '${dailyMealProtein.toStringAsFixed(1)} g'
                            : '--',
                        icon: Icons.egg_alt_outlined,
                      ),
                      _MetricChip(
                        label: 'Carbs',
                        value: dailyMealCarbs != null
                            ? '${dailyMealCarbs.toStringAsFixed(1)} g'
                            : '--',
                        icon: Icons.grain_outlined,
                      ),
                      _MetricChip(
                        label: 'Fat',
                        value: dailyMealFat != null
                            ? '${dailyMealFat.toStringAsFixed(1)} g'
                            : '--',
                        icon: Icons.opacity_outlined,
                      ),
                      _MetricChip(
                        label: 'Calories left',
                        value: caloriesRemaining != null
                            ? '$caloriesRemaining kcal'
                            : '--',
                        icon: Icons.flag_outlined,
                      ),
                      _MetricChip(
                        label: 'Protein left',
                        value: proteinRemaining != null
                            ? '${proteinRemaining.toStringAsFixed(1)} g'
                            : '--',
                        icon: Icons.track_changes_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TwoColumnFields(
                    left: _NumberField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      icon: Icons.monitor_weight_outlined,
                    ),
                    right: _NumberField(
                      controller: _calorieGoalController,
                      label: 'Calorie goal',
                      icon: Icons.flag_outlined,
                      allowDecimal: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoColumnFields(
                    left: _NumberField(
                      controller: _proteinGoalController,
                      label: 'Protein goal (g)',
                      icon: Icons.fitness_center_outlined,
                    ),
                    right: TextField(
                      controller: _workoutNameController,
                      decoration: const InputDecoration(
                        labelText: 'Workout name',
                        hintText: 'Push Day, Pull, Legs, Mobility...',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoColumnFields(
                    left: _NumberField(
                      controller: _durationController,
                      label: 'Workout duration (min)',
                      icon: Icons.timer_outlined,
                      allowDecimal: false,
                    ),
                    right: _ReadOnlyField(
                      label: 'Body fat %',
                      value: _derivedBodyFat?.toStringAsFixed(1) ?? '--',
                      icon: Icons.insights_outlined,
                      helperText: 'Calculated from waist, neck, and height.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoColumnFields(
                    left: _NumberField(
                      controller: _waistController,
                      label: 'Waist (cm)',
                      icon: Icons.straighten_rounded,
                    ),
                    right: _NumberField(
                      controller: _neckController,
                      label: 'Neck (cm)',
                      icon: Icons.accessibility_new_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height_rounded,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText:
                          'Recovery, hunger, energy, steps, soreness, or anything else worth remembering.',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  if (existingEntry != null && _editingEntryId == null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'A saved entry already exists for this date. Saving will update it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF617260),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Food Master',
              subtitle:
                  'Search or filter foods, then tap Add to drop them into today\'s log. The seeded foods from your older JSON are already pinned into My Foods and Recently Logged.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _foodSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Search foods',
                      hintText: 'Rice, whey, curd, shawarma...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFoodCategory.isEmpty
                        ? null
                        : _selectedFoodCategory,
                    decoration: const InputDecoration(
                      labelText: 'Filter by category',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All categories'),
                      ),
                      ...mealCategories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFoodCategory = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FoodMasterSection.values
                        .map(
                          (section) => ChoiceChip(
                            label: Text(_foodSectionLabel(section)),
                            selected: _foodSection == section,
                            onSelected: (_) {
                              setState(() {
                                _foodSection = section;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  if (_visibleFoodItems.isEmpty)
                    const Text('No foods matched the current search/filter.')
                  else
                    Column(
                      children: _visibleFoodItems
                          .take(18)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FoodMasterTile(
                                item: item,
                                onAdd: () => _addFoodFromMaster(item),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addCustomFoodDraft,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Create custom food'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Today\'s Foods',
              subtitle:
                  'Adjust quantity and custom macros here. Duplicate adds increase quantity instead of cluttering the log.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _foodDrafts.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _foodDrafts.length - 1 ? 0 : 12,
                      ),
                      child: _FoodDraftCard(
                        index: index,
                        draft: _foodDrafts[index],
                        availableItems: _allFoodItems,
                        canRemove: _foodDrafts.length > 1,
                        onChanged: _triggerRebuild,
                        onRemove: () {
                          final removed = _foodDrafts.removeAt(index);
                          removed.dispose();
                          setState(() {});
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _foodDrafts.add(_createFoodDraft());
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add food row'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Workout Master',
              subtitle:
                  'Browse a full exercise list by muscle group or type, then add it into a set-wise session.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _exerciseSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Search exercises',
                      hintText: 'Bench press, lat pulldown, plank...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExerciseCategory.isEmpty
                        ? null
                        : _selectedExerciseCategory,
                    decoration: const InputDecoration(
                      labelText: 'Filter by muscle group',
                      prefixIcon: Icon(Icons.fitness_center_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All groups'),
                      ),
                      ...workoutCategories
                          .where((item) => item != restDayWorkoutCategory)
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedExerciseCategory = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExerciseType.isEmpty
                        ? null
                        : _selectedExerciseType,
                    decoration: const InputDecoration(
                      labelText: 'Filter by exercise type',
                      prefixIcon: Icon(Icons.tune_rounded),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('All types'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'strength',
                        child: Text('Strength'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'cardio',
                        child: Text('Cardio'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'HIIT',
                        child: Text('HIIT'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'mobility',
                        child: Text('Mobility'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'stretching',
                        child: Text('Stretching'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedExerciseType = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_visibleExercises.isEmpty)
                    const Text('No exercises matched the current search/filter.')
                  else
                    Column(
                      children: _visibleExercises
                          .take(18)
                          .map(
                            (exercise) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ExerciseMasterTile(
                                exercise: exercise,
                                onAdd: () => _addExerciseFromMaster(exercise),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addCustomExerciseDraft,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Create custom exercise'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Workout Session',
              subtitle:
                  'Track exercises set by set, see the last logged top weight, and compare today\'s work against your previous session.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _exerciseDrafts.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _exerciseDrafts.length - 1 ? 0 : 12,
                      ),
                      child: _ExerciseDraftCard(
                        index: index,
                        draft: _exerciseDrafts[index],
                        availableExercises: _allExercises,
                        previousSnapshot: _previousExerciseSnapshot(
                          _exerciseDrafts[index].resolvedName,
                        ),
                        canRemove: _exerciseDrafts.length > 1,
                        onChanged: _triggerRebuild,
                        onRemove: () {
                          final removed = _exerciseDrafts.removeAt(index);
                          removed.dispose();
                          setState(() {});
                        },
                        onAddSet: () {
                          _exerciseDrafts[index].addSet();
                          _triggerRebuild();
                        },
                        onRemoveSet: (setIndex) {
                          _exerciseDrafts[index].removeSetAt(setIndex);
                          _triggerRebuild();
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _exerciseDrafts.add(_createExerciseDraft());
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add exercise row'),
                  ),
                  if (draftEntry != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricChip(
                          label: 'Exercises',
                          value: draftEntry.totalExercises.toString(),
                          icon: Icons.sports_gymnastics_rounded,
                        ),
                        _MetricChip(
                          label: 'Sets',
                          value: draftEntry.totalSets.toString(),
                          icon: Icons.repeat_rounded,
                        ),
                        _MetricChip(
                          label: 'Volume',
                          value:
                              '${draftEntry.workoutVolume.toStringAsFixed(0)} kg',
                          icon: Icons.bar_chart_rounded,
                        ),
                        _MetricChip(
                          label: 'Cardio cals',
                          value: '${draftEntry.cardioCaloriesBurned} kcal',
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'History',
              subtitle:
                  'Edit older daily logs, and review workout history by date with session names and set summaries.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recentEntries.isEmpty)
                    const Text('No saved entries yet.')
                  else
                    Column(
                      children: recentEntries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HistoryEntryCard(
                                entry: entry,
                                onEdit: () => _loadEntry(entry),
                                onDelete: () => _deleteEntry(entry),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  if (workoutHistory.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Workout history by date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: workoutHistory
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _WorkoutHistoryTile(entry: entry),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveEntry,
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text('Save entry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resetForm(prefillHeight: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset form'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({
    required this.selectedDate,
    required this.onPickDate,
    required this.onOpenDashboard,
    required this.onHeaderActionSelected,
    required this.isEditing,
  });

  final DateTime selectedDate;
  final Future<void> Function() onPickDate;
  final VoidCallback onOpenDashboard;
  final Future<void> Function(_HeaderAction action) onHeaderActionSelected;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D7A57).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isEditing ? 'Editing saved entry' : 'Food + Workout Master',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D7A57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'LiftLedger',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local-first logging with a bigger food database, set-wise workouts, and fast daily totals.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF617260),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_HeaderAction>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (action) => onHeaderActionSelected(action),
              itemBuilder: (context) => const [
                PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.exportCsv,
                  child: Text('Export CSV'),
                ),
                PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.backupJson,
                  child: Text('Backup JSON'),
                ),
                PopupMenuItem<_HeaderAction>(
                  value: _HeaderAction.restoreJson,
                  child: Text('Restore JSON'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(DateFormat('EEE, MMM d').format(selectedDate)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onOpenDashboard,
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Dashboard'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF617260),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D7A57)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF617260),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodMasterTile extends StatelessWidget {
  const _FoodMasterTile({required this.item, required this.onAdd});

  final MealItemMaster item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${item.servingSize}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF617260),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.calories.toStringAsFixed(0)} kcal • '
                  'P ${item.protein.toStringAsFixed(1)} • '
                  'C ${item.carbs.toStringAsFixed(1)} • '
                  'F ${item.fat.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.source,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF617260),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMasterTile extends StatelessWidget {
  const _ExerciseMasterTile({
    required this.exercise,
    required this.onAdd,
  });

  final ExerciseMaster exercise;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.muscleGroup} • ${exercise.exerciseType} • ${exercise.difficulty}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF617260),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.primaryMuscle} • ${exercise.equipment}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.source,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF617260),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FoodDraftCard extends StatelessWidget {
  const _FoodDraftCard({
    required this.index,
    required this.draft,
    required this.availableItems,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _FoodDraft draft;
  final List<MealItemMaster> availableItems;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final itemNames = availableItems.map((item) => item.name).toList(growable: true)
      ..sort();
    if (!itemNames.contains(_customFoodValue)) {
      itemNames.add(_customFoodValue);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF5F7F3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Food ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.selectedFoodName.isEmpty
                ? null
                : draft.selectedFoodName,
            decoration: const InputDecoration(
              labelText: 'Food item',
              prefixIcon: Icon(Icons.restaurant_menu_rounded),
            ),
            items: itemNames
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item == _customFoodValue ? 'Custom food' : item,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              draft.updateFoodSelection(value ?? '');
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          if (draft.isCustom) ...[
            _TwoColumnFields(
              left: TextField(
                controller: draft.customNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom food name',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              right: TextField(
                controller: draft.customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Food category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _TwoColumnFields(
              left: _NumberField(
                controller: draft.customServingSizeController,
                label: 'Default serving size',
                icon: Icons.scale_outlined,
              ),
              right: DropdownButtonFormField<String>(
                initialValue: draft.selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'gram', child: Text('gram')),
                  DropdownMenuItem(value: 'piece', child: Text('piece')),
                  DropdownMenuItem(value: 'scoop', child: Text('scoop')),
                  DropdownMenuItem(value: 'cup', child: Text('cup')),
                  DropdownMenuItem(value: 'serving', child: Text('serving')),
                ],
                onChanged: (value) {
                  draft.selectedUnit = value ?? 'serving';
                  onChanged();
                },
              ),
            ),
            const SizedBox(height: 12),
            _TwoColumnFields(
              left: TextField(
                controller: draft.customCaloriesController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Calories / serving',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                ),
              ),
              right: TextField(
                controller: draft.customProteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Protein / serving (g)',
                  prefixIcon: Icon(Icons.egg_alt_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _TwoColumnFields(
              left: TextField(
                controller: draft.customCarbsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Carbs / serving (g)',
                  prefixIcon: Icon(Icons.grain_outlined),
                ),
              ),
              right: TextField(
                controller: draft.customFatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Fat / serving (g)',
                  prefixIcon: Icon(Icons.opacity_outlined),
                ),
              ),
            ),
          ] else
            _TwoColumnFields(
              left: _ReadOnlyField(
                label: 'Serving size',
                value: draft.servingLabel.isNotEmpty
                    ? draft.servingLabel
                    : 'Select a food item',
                icon: Icons.scale_outlined,
                helperText: 'Values are stored per default serving.',
              ),
              right: _ReadOnlyField(
                label: 'Source',
                value: draft.source.isNotEmpty ? draft.source : '--',
                icon: Icons.link_outlined,
                helperText: draft.resolvedCategory,
              ),
            ),
          const SizedBox(height: 12),
          _NumberField(
            controller: draft.quantityController,
            label: 'Quantity',
            icon: Icons.exposure_plus_1_rounded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                label: 'Calories',
                value: draft.totalCalories != null
                    ? '${draft.totalCalories} kcal'
                    : '--',
                icon: Icons.local_fire_department_outlined,
              ),
              _MetricChip(
                label: 'Protein',
                value: draft.totalProtein != null
                    ? '${draft.totalProtein!.toStringAsFixed(1)} g'
                    : '--',
                icon: Icons.egg_alt_outlined,
              ),
              _MetricChip(
                label: 'Carbs',
                value: draft.totalCarbs != null
                    ? '${draft.totalCarbs!.toStringAsFixed(1)} g'
                    : '--',
                icon: Icons.grain_outlined,
              ),
              _MetricChip(
                label: 'Fat',
                value: draft.totalFat != null
                    ? '${draft.totalFat!.toStringAsFixed(1)} g'
                    : '--',
                icon: Icons.opacity_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseDraftCard extends StatelessWidget {
  const _ExerciseDraftCard({
    required this.index,
    required this.draft,
    required this.availableExercises,
    required this.previousSnapshot,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  final int index;
  final _ExerciseDraft draft;
  final List<ExerciseMaster> availableExercises;
  final _ExerciseHistorySnapshot? previousSnapshot;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final void Function(int index) onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final exerciseNames = availableExercises
        .map((exercise) => exercise.name)
        .toList(growable: true)
      ..sort();
    if (!exerciseNames.contains(_customExerciseValue)) {
      exerciseNames.add(_customExerciseValue);
    }

    final currentTopWeight = draft.currentTopWeight;
    final currentVolume = draft.currentVolume;
    final topWeightDelta =
        previousSnapshot != null && previousSnapshot!.topWeightKg > 0
        ? currentTopWeight - previousSnapshot!.topWeightKg
        : null;
    final volumeDelta =
        previousSnapshot != null && previousSnapshot!.volume > 0
        ? currentVolume - previousSnapshot!.volume
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF5F7F3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exercise ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.selectedExerciseName.isEmpty
                ? null
                : draft.selectedExerciseName,
            decoration: const InputDecoration(
              labelText: 'Exercise name',
              prefixIcon: Icon(Icons.sports_gymnastics_rounded),
            ),
            items: exerciseNames
                .map(
                  (name) => DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      name == _customExerciseValue
                          ? 'Custom exercise'
                          : name,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              draft.updateExerciseSelection(value ?? '');
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          if (draft.isCustom) ...[
            _TwoColumnFields(
              left: TextField(
                controller: draft.customNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom exercise name',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              right: TextField(
                controller: draft.customPrimaryMuscleController,
                decoration: const InputDecoration(
                  labelText: 'Primary muscle',
                  prefixIcon: Icon(Icons.accessibility_new_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _TwoColumnFields(
              left: DropdownButtonFormField<String>(
                initialValue: draft.selectedMuscleGroup,
                decoration: const InputDecoration(
                  labelText: 'Muscle group',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
                items: workoutCategories
                    .where((item) => item != restDayWorkoutCategory)
                    .map(
                      (group) => DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  draft.selectedMuscleGroup = value ?? '';
                  onChanged();
                },
              ),
              right: DropdownButtonFormField<String>(
                initialValue: draft.selectedExerciseType,
                decoration: const InputDecoration(
                  labelText: 'Exercise type',
                  prefixIcon: Icon(Icons.tune_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'strength', child: Text('strength')),
                  DropdownMenuItem(value: 'cardio', child: Text('cardio')),
                  DropdownMenuItem(value: 'HIIT', child: Text('HIIT')),
                  DropdownMenuItem(value: 'mobility', child: Text('mobility')),
                  DropdownMenuItem(
                    value: 'stretching',
                    child: Text('stretching'),
                  ),
                ],
                onChanged: (value) {
                  draft.selectedExerciseType = value ?? 'strength';
                  onChanged();
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.customEquipmentController,
              decoration: const InputDecoration(
                labelText: 'Equipment',
                prefixIcon: Icon(Icons.handyman_outlined),
              ),
            ),
          ] else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Group',
                  value: draft.resolvedMuscleGroup.isNotEmpty
                      ? draft.resolvedMuscleGroup
                      : '--',
                  icon: Icons.fitness_center_rounded,
                ),
                _MetricChip(
                  label: 'Type',
                  value: draft.resolvedExerciseType.isNotEmpty
                      ? draft.resolvedExerciseType
                      : '--',
                  icon: Icons.tune_rounded,
                ),
                _MetricChip(
                  label: 'Equipment',
                  value: draft.resolvedEquipment.isNotEmpty
                      ? draft.resolvedEquipment
                      : '--',
                  icon: Icons.handyman_outlined,
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (previousSnapshot != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last logged ${DateFormat('MMM d').format(previousSnapshot!.date)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF617260),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previousSnapshot!.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricChip(
                        label: 'Previous top',
                        value:
                            '${previousSnapshot!.topWeightKg.toStringAsFixed(1)} kg',
                        icon: Icons.trending_up_rounded,
                      ),
                      _MetricChip(
                        label: 'Current top',
                        value: '${currentTopWeight.toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight_outlined,
                      ),
                      _MetricChip(
                        label: 'Top weight delta',
                        value: topWeightDelta == null
                            ? '--'
                            : '${topWeightDelta >= 0 ? '+' : ''}${topWeightDelta.toStringAsFixed(1)} kg',
                        icon: Icons.compare_arrows_rounded,
                      ),
                      _MetricChip(
                        label: 'Volume delta',
                        value: volumeDelta == null
                            ? '--'
                            : '${volumeDelta >= 0 ? '+' : ''}${volumeDelta.toStringAsFixed(0)} kg',
                        icon: Icons.bar_chart_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Text(
              'No previous log found yet for this exercise.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF617260),
              ),
            ),
          const SizedBox(height: 12),
          _TwoColumnFields(
            left: _NumberField(
              controller: draft.durationController,
              label: 'Duration (min)',
              icon: Icons.timer_outlined,
              allowDecimal: false,
            ),
            right: _NumberField(
              controller: draft.caloriesBurnedController,
              label: 'Calories burned',
              icon: Icons.local_fire_department_outlined,
              allowDecimal: false,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Exercise notes',
              hintText: 'Tempo, machine used, RPE, stance, setup...',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sets',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var setIndex = 0; setIndex < draft.setDrafts.length; setIndex++)
            Padding(
              padding: EdgeInsets.only(
                bottom: setIndex == draft.setDrafts.length - 1 ? 0 : 10,
              ),
              child: _SetRow(
                setNumber: setIndex + 1,
                draft: draft.setDrafts[setIndex],
                canRemove: draft.setDrafts.length > 1,
                onRemove: () => onRemoveSet(setIndex),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add set'),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int setNumber;
  final _SetDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            'Set $setNumber',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: draft.repsController,
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: const InputDecoration(
              labelText: 'Reps',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: draft.weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
        ),
        if (canRemove) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
        ],
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FitnessEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final macroLine = [
      if (entry.totalCalories != null) '${entry.totalCalories} kcal',
      if (entry.totalProteinGrams != null)
        '${entry.totalProteinGrams!.toStringAsFixed(1)} g protein',
      if (entry.totalCarbsGrams != null)
        '${entry.totalCarbsGrams!.toStringAsFixed(1)} g carbs',
      if (entry.totalFatGrams != null)
        '${entry.totalFatGrams!.toStringAsFixed(1)} g fat',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF6F8F3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEE, MMM d, yyyy').format(entry.date),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (macroLine.isNotEmpty)
            Text(
              macroLine,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (entry.workoutName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Workout: ${entry.workoutName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (entry.mealsSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.mealsSummary,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF617260)),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({required this.entry});

  final FitnessEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEE, MMM d').format(entry.date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            entry.workoutName.trim().isNotEmpty
                ? entry.workoutName
                : entry.muscleGroups.join(', '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.totalExercises} exercises • ${entry.totalSets} sets • ${entry.workoutVolume.toStringAsFixed(0)} kg volume',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF617260)),
          ),
          const SizedBox(height: 6),
          Text(
            entry.exercises.map((exercise) => exercise.summary).join('\n'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(height: 12), right],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.allowDecimal = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    this.helperText,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _FoodDraft {
  _FoodDraft({
    this.selectedFoodName = '',
    this.selectedUnit = 'serving',
    String quantity = '1',
    String customName = '',
    String customCategory = '',
    String customServingSize = '1',
    String customCalories = '',
    String customProtein = '',
    String customCarbs = '',
    String customFat = '',
  }) : quantityController = TextEditingController(
         text: quantity.trim().isEmpty ? '1' : quantity,
       ),
       customNameController = TextEditingController(text: customName),
       customCategoryController = TextEditingController(text: customCategory),
       customServingSizeController = TextEditingController(
         text: customServingSize,
       ),
       customCaloriesController = TextEditingController(text: customCalories),
       customProteinController = TextEditingController(text: customProtein),
       customCarbsController = TextEditingController(text: customCarbs),
       customFatController = TextEditingController(text: customFat);

  factory _FoodDraft.fromMeal(MealEntry meal) {
    final master = mealItemByName(meal.itemName);
    final isCustom = meal.isCustomFood || master == null;
    return _FoodDraft(
      selectedFoodName: isCustom ? _customFoodValue : meal.itemName,
      selectedUnit: isCustom
          ? (meal.unit.isEmpty ? 'serving' : meal.unit)
          : (master?.unit ?? 'serving'),
      quantity: _formatControllerNumber(meal.normalizedQuantity),
      customName: isCustom ? meal.itemName : '',
      customCategory: isCustom ? meal.effectiveFoodCategory : '',
      customServingSize: isCustom
          ? _formatControllerNumber(meal.defaultServingSize ?? 1)
          : _formatControllerNumber(master?.defaultServingSize ?? 1),
      customCalories: isCustom
          ? _formatControllerNumber(meal.effectiveCaloriesPerServing)
          : '',
      customProtein: isCustom
          ? _formatControllerNumber(meal.effectiveProteinPerServing)
          : '',
      customCarbs: isCustom
          ? _formatControllerNumber(meal.carbsPerServing)
          : '',
      customFat: isCustom
          ? _formatControllerNumber(meal.fatPerServing)
          : '',
    );
  }

  String selectedFoodName;
  String selectedUnit;
  final TextEditingController quantityController;
  final TextEditingController customNameController;
  final TextEditingController customCategoryController;
  final TextEditingController customServingSizeController;
  final TextEditingController customCaloriesController;
  final TextEditingController customProteinController;
  final TextEditingController customCarbsController;
  final TextEditingController customFatController;

  List<TextEditingController> get controllers => <TextEditingController>[
    quantityController,
    customNameController,
    customCategoryController,
    customServingSizeController,
    customCaloriesController,
    customProteinController,
    customCarbsController,
    customFatController,
  ];

  bool get isCustom => selectedFoodName == _customFoodValue;

  MealItemMaster? get selectedMaster =>
      isCustom ? null : mealItemByName(selectedFoodName);

  String get resolvedName => isCustom
      ? customNameController.text.trim()
      : (selectedMaster?.name ?? selectedFoodName.trim());

  String get resolvedCategory => isCustom
      ? customCategoryController.text.trim()
      : (selectedMaster?.category ?? '');

  double get resolvedServingSize =>
      _parseDraftDouble(customServingSizeController) ??
      selectedMaster?.defaultServingSize ??
      1;

  String get resolvedUnit => isCustom
      ? selectedUnit
      : (selectedMaster?.unit.isNotEmpty == true
            ? selectedMaster!.unit
            : 'serving');

  String get servingLabel => _buildServingLabel(resolvedServingSize, resolvedUnit);

  double get quantity {
    final parsed = _parseDraftDouble(quantityController);
    if (parsed == null || parsed <= 0) {
      return 1;
    }
    return parsed;
  }

  void incrementQuantity() {
    quantityController.text = (quantity + 1).toStringAsFixed(
      quantity + 1 == (quantity + 1).roundToDouble() ? 0 : 1,
    );
  }

  double? get caloriesPerServing => isCustom
      ? _parseDraftDouble(customCaloriesController)
      : selectedMaster?.calories;

  double? get proteinPerServing => isCustom
      ? _parseDraftDouble(customProteinController)
      : selectedMaster?.protein;

  double? get carbsPerServing => isCustom
      ? _parseDraftDouble(customCarbsController)
      : selectedMaster?.carbs;

  double? get fatPerServing => isCustom
      ? _parseDraftDouble(customFatController)
      : selectedMaster?.fat;

  String get source => isCustom
      ? 'Custom food'
      : (selectedMaster?.source ?? '');

  int? get totalCalories {
    final perServing = caloriesPerServing;
    if (perServing == null) {
      return null;
    }
    return (perServing * quantity).round();
  }

  double? get totalProtein {
    final perServing = proteinPerServing;
    if (perServing == null) {
      return null;
    }
    return double.parse((perServing * quantity).toStringAsFixed(1));
  }

  double? get totalCarbs {
    final perServing = carbsPerServing;
    if (perServing == null) {
      return null;
    }
    return double.parse((perServing * quantity).toStringAsFixed(1));
  }

  double? get totalFat {
    final perServing = fatPerServing;
    if (perServing == null) {
      return null;
    }
    return double.parse((perServing * quantity).toStringAsFixed(1));
  }

  void updateFoodSelection(String value) {
    selectedFoodName = value.trim();
    if (!isCustom && selectedMaster != null) {
      selectedUnit = selectedMaster!.unit;
    }
  }

  MealItemMaster? asCustomMaster() {
    if (!isCustom || resolvedName.isEmpty) {
      return null;
    }
    return MealItemMaster(
      name: resolvedName,
      category: resolvedCategory.isEmpty ? 'Custom Foods' : resolvedCategory,
      defaultServingSize: resolvedServingSize,
      unit: resolvedUnit,
      calories: caloriesPerServing ?? 0,
      protein: proteinPerServing ?? 0,
      carbs: carbsPerServing ?? 0,
      fat: fatPerServing ?? 0,
      source: 'Custom food',
      isCustomFood: true,
      isRecentlyLogged: true,
    );
  }

  MealEntry toMeal() {
    return MealEntry(
      name: resolvedCategory.isEmpty ? 'Food' : resolvedCategory,
      foods: resolvedName,
      category: resolvedCategory,
      foodCategory: resolvedCategory,
      servingSize: servingLabel,
      defaultServingSize: resolvedServingSize,
      unit: resolvedUnit,
      quantity: quantity,
      caloriesPerServing: caloriesPerServing,
      proteinPerServing: proteinPerServing,
      carbsPerServing: carbsPerServing,
      fatPerServing: fatPerServing,
      source: source,
      isCustomFood: isCustom,
      isRecentlyLogged: true,
      calories: totalCalories,
      proteinGrams: totalProtein,
    );
  }

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

class _SetDraft {
  _SetDraft({String reps = '', String weightKg = ''})
    : repsController = TextEditingController(text: reps),
      weightController = TextEditingController(text: weightKg);

  factory _SetDraft.fromSet(WorkoutSetEntry setEntry) {
    return _SetDraft(
      reps: setEntry.reps == 0 ? '' : setEntry.reps.toString(),
      weightKg: setEntry.weightKg == 0
          ? ''
          : _formatControllerNumber(setEntry.weightKg),
    );
  }

  final TextEditingController repsController;
  final TextEditingController weightController;

  List<TextEditingController> get controllers => <TextEditingController>[
    repsController,
    weightController,
  ];

  WorkoutSetEntry toSet() {
    return WorkoutSetEntry(
      reps: int.tryParse(repsController.text.trim()) ?? 0,
      weightKg:
          double.tryParse(weightController.text.replaceAll(',', '.').trim()) ??
          0,
    );
  }

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    this.selectedExerciseName = '',
    this.selectedMuscleGroup = 'Chest',
    this.selectedExerciseType = 'strength',
    String customName = '',
    String customPrimaryMuscle = '',
    String customEquipment = '',
    String duration = '',
    String caloriesBurned = '',
    String notes = '',
    List<_SetDraft>? setDrafts,
  }) : customNameController = TextEditingController(text: customName),
       customPrimaryMuscleController = TextEditingController(
         text: customPrimaryMuscle,
       ),
       customEquipmentController = TextEditingController(text: customEquipment),
       durationController = TextEditingController(text: duration),
       caloriesBurnedController = TextEditingController(text: caloriesBurned),
       notesController = TextEditingController(text: notes),
       setDrafts = setDrafts ?? <_SetDraft>[_SetDraft()];

  factory _ExerciseDraft.fromExercise(WorkoutExercise exercise) {
    final master = exerciseByName(exercise.exerciseName);
    final isCustom = exercise.isCustomExercise || master == null;
    final setDrafts = exercise.effectiveSets.isEmpty
        ? <_SetDraft>[_SetDraft()]
        : exercise.effectiveSets
              .map((setEntry) => _SetDraft.fromSet(setEntry))
              .toList(growable: false);

    return _ExerciseDraft(
      selectedExerciseName: isCustom
          ? _customExerciseValue
          : exercise.exerciseName,
      selectedMuscleGroup: isCustom
          ? (exercise.workoutType.isEmpty ? 'Chest' : exercise.workoutType)
          : (master?.muscleGroup ?? exercise.workoutType),
      selectedExerciseType: isCustom
          ? (exercise.exerciseType.isEmpty ? 'strength' : exercise.exerciseType)
          : (master?.exerciseType ?? exercise.exerciseType),
      customName: isCustom ? exercise.exerciseName : '',
      customPrimaryMuscle: isCustom ? exercise.primaryMuscle : '',
      customEquipment: isCustom ? exercise.equipment : '',
      duration: exercise.durationMinutes == 0
          ? ''
          : exercise.durationMinutes.toString(),
      caloriesBurned: exercise.caloriesBurned == 0
          ? ''
          : exercise.caloriesBurned.toString(),
      notes: exercise.notes,
      setDrafts: setDrafts,
    );
  }

  String selectedExerciseName;
  String selectedMuscleGroup;
  String selectedExerciseType;
  final TextEditingController customNameController;
  final TextEditingController customPrimaryMuscleController;
  final TextEditingController customEquipmentController;
  final TextEditingController durationController;
  final TextEditingController caloriesBurnedController;
  final TextEditingController notesController;
  final List<_SetDraft> setDrafts;

  List<TextEditingController> get controllers => <TextEditingController>[
    customNameController,
    customPrimaryMuscleController,
    customEquipmentController,
    durationController,
    caloriesBurnedController,
    notesController,
  ];

  bool get isCustom => selectedExerciseName == _customExerciseValue;

  ExerciseMaster? get selectedMaster =>
      isCustom ? null : exerciseByName(selectedExerciseName);

  String get resolvedName => isCustom
      ? customNameController.text.trim()
      : (selectedMaster?.name ?? selectedExerciseName.trim());

  String get resolvedMuscleGroup => isCustom
      ? selectedMuscleGroup
      : (selectedMaster?.muscleGroup ?? selectedMuscleGroup);

  String get resolvedPrimaryMuscle => isCustom
      ? customPrimaryMuscleController.text.trim()
      : (selectedMaster?.primaryMuscle ?? '');

  String get resolvedEquipment => isCustom
      ? customEquipmentController.text.trim()
      : (selectedMaster?.equipment ?? '');

  String get resolvedDifficulty => isCustom
      ? 'Custom'
      : (selectedMaster?.difficulty ?? '');

  String get resolvedExerciseType => isCustom
      ? selectedExerciseType
      : (selectedMaster?.exerciseType ?? selectedExerciseType);

  String get resolvedInstructions => isCustom
      ? 'Custom exercise'
      : (selectedMaster?.instructions ?? '');

  String get source => isCustom
      ? 'Custom exercise'
      : (selectedMaster?.source ?? '');

  int get currentTotalSets =>
      setDrafts.map((setDraft) => setDraft.toSet()).where((setEntry) => setEntry.isMeaningful).length;

  double get currentTopWeight {
    return setDrafts
        .map((setDraft) => setDraft.toSet().weightKg)
        .fold<double>(0, (running, value) => value > running ? value : running);
  }

  double get currentVolume {
    return setDrafts
        .map((setDraft) => setDraft.toSet())
        .fold<double>(
          0,
          (running, setEntry) => running + (setEntry.reps * setEntry.weightKg),
        );
  }

  void updateExerciseSelection(String value) {
    selectedExerciseName = value.trim();
    if (!isCustom && selectedMaster != null) {
      selectedMuscleGroup = selectedMaster!.muscleGroup;
      selectedExerciseType = selectedMaster!.exerciseType;
    }
  }

  void addSet() {
    setDrafts.add(_SetDraft());
  }

  void removeSetAt(int index) {
    if (setDrafts.length == 1) {
      return;
    }
    final removed = setDrafts.removeAt(index);
    removed.dispose();
  }

  ExerciseMaster? asCustomMaster() {
    if (!isCustom || resolvedName.isEmpty) {
      return null;
    }
    return ExerciseMaster(
      name: resolvedName,
      muscleGroup: resolvedMuscleGroup,
      primaryMuscle: resolvedPrimaryMuscle,
      secondaryMuscles: const <String>[],
      equipment: resolvedEquipment.isEmpty ? 'Custom' : resolvedEquipment,
      difficulty: 'Custom',
      exerciseType: resolvedExerciseType,
      instructions: 'Custom exercise',
      source: 'Custom exercise',
      isCustomExercise: true,
    );
  }

  WorkoutExercise toExercise() {
    final sets = setDrafts
        .map((setDraft) => setDraft.toSet())
        .where((setEntry) => setEntry.isMeaningful)
        .toList(growable: false);
    return WorkoutExercise(
      workoutType: resolvedMuscleGroup,
      exerciseName: resolvedName,
      sets: sets.length,
      reps: sets.isNotEmpty ? sets.first.reps : 0,
      weightKg: sets.isNotEmpty ? sets.first.weightKg : 0,
      performedSets: sets,
      durationMinutes: int.tryParse(durationController.text.trim()) ?? 0,
      caloriesBurned:
          int.tryParse(caloriesBurnedController.text.trim()) ?? 0,
      notes: notesController.text.trim(),
      primaryMuscle: resolvedPrimaryMuscle,
      secondaryMuscles: const <String>[],
      equipment: resolvedEquipment,
      difficulty: resolvedDifficulty,
      exerciseType: resolvedExerciseType,
      instructions: resolvedInstructions,
      source: source,
      isCustomExercise: isCustom,
    );
  }

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final setDraft in setDrafts) {
      setDraft.dispose();
    }
  }
}

class _ExerciseHistorySnapshot {
  const _ExerciseHistorySnapshot({
    required this.date,
    required this.topWeightKg,
    required this.volume,
    required this.totalSets,
    required this.summary,
  });

  final DateTime date;
  final double topWeightKg;
  final double volume;
  final int totalSets;
  final String summary;
}

String _foodSectionLabel(FoodMasterSection section) {
  return switch (section) {
    FoodMasterSection.allFoods => 'All Foods',
    FoodMasterSection.myFoods => 'My Foods',
    FoodMasterSection.recent => 'Recently Logged',
    FoodMasterSection.highProtein => 'High Protein',
    FoodMasterSection.carbs => 'Carbs',
    FoodMasterSection.fats => 'Fats',
    FoodMasterSection.customFoods => 'Custom Foods',
  };
}

double? _parseDouble(TextEditingController controller) {
  final value = controller.text.replaceAll(',', '.').trim();
  if (value.isEmpty) {
    return null;
  }
  return double.tryParse(value);
}

int? _parseInt(TextEditingController controller) {
  final value = controller.text.trim();
  if (value.isEmpty) {
    return null;
  }
  return int.tryParse(value);
}

double? _parseDraftDouble(TextEditingController controller) {
  return _parseDouble(controller);
}

String _formatControllerValue(num? value) {
  if (value == null) {
    return '';
  }
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String _formatControllerNumber(num? value) => _formatControllerValue(value);

String _buildServingLabel(double amount, String unit) {
  final amountLabel = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(1);
  final unitLabel = amount == 1
      ? unit
      : (unit == 'piece' ? 'pieces' : unit);
  return '$amountLabel $unitLabel';
}
