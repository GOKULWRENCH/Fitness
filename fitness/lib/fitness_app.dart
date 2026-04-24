import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/fitness_entry.dart';
import 'services/fitness_repository.dart';
import 'services/web_file_service.dart';
import 'utils/data_exports.dart';
import 'utils/fitness_calculations.dart';

enum AppTab { home, dashboard }

enum HeaderAction { exportCsv, backupJson, restoreJson }

enum ReportPreset { week, month, quarter, halfYear, custom }

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key, required this.repository});

  final FitnessRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D7A57),
      primary: const Color(0xFF1D7A57),
      secondary: const Color(0xFFF28452),
      surface: const Color(0xFFFCFBF6),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'LiftLedger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F1E8),
        fontFamily: 'Avenir Next',
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.78),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.88),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          helperStyle: TextStyle(
            color: const Color(0xFF6D756B).withValues(alpha: 0.92),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A352A),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary),
          ),
        ),
      ),
      home: FitnessAppShell(repository: repository),
    );
  }
}

class FitnessAppShell extends StatefulWidget {
  const FitnessAppShell({super.key, required this.repository});

  final FitnessRepository repository;

  @override
  State<FitnessAppShell> createState() => _FitnessAppShellState();
}

class _FitnessAppShellState extends State<FitnessAppShell> {
  AppTab _selectedTab = AppTab.home;
  ReportPreset _preset = ReportPreset.halfYear;
  DateTimeRange? _customRange;

  DateTimeRange _resolveRange(List<FitnessEntry> entries) {
    final today = FitnessEntry.normalizedDate(DateTime.now());
    if (_preset == ReportPreset.custom && _customRange != null) {
      return DateTimeRange(
        start: FitnessEntry.normalizedDate(_customRange!.start),
        end: FitnessEntry.normalizedDate(_customRange!.end),
      );
    }

    switch (_preset) {
      case ReportPreset.week:
        return DateTimeRange(start: startOfWeek(today), end: today);
      case ReportPreset.month:
        return DateTimeRange(
          start: DateTime(today.year, today.month),
          end: today,
        );
      case ReportPreset.quarter:
        return DateTimeRange(
          start: DateTime(today.year, today.month - 2),
          end: today,
        );
      case ReportPreset.halfYear:
        return DateTimeRange(
          start: DateTime(today.year, today.month - 5),
          end: today,
        );
      case ReportPreset.custom:
        final fallbackStart = entries.isEmpty
            ? today.subtract(const Duration(days: 89))
            : entries.first.date;
        return DateTimeRange(start: fallbackStart, end: today);
    }
  }

  List<FitnessEntry> _filterEntries(
    List<FitnessEntry> entries,
    DateTimeRange range,
  ) {
    return entries
        .where(
          (entry) =>
              !entry.date.isBefore(range.start) &&
              !entry.date.isAfter(range.end),
        )
        .toList(growable: false);
  }

  Future<void> _handleHeaderAction(HeaderAction action) async {
    switch (action) {
      case HeaderAction.exportCsv:
        await _exportCsv();
      case HeaderAction.backupJson:
        await _backupJson();
      case HeaderAction.restoreJson:
        await _restoreJson();
    }
  }

  Future<void> _exportCsv() async {
    final entries = widget.repository.entries;
    if (entries.isEmpty) {
      _showMessage('Add at least one log before exporting CSV.');
      return;
    }

    final filename =
        'fitness-export-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    await WebFileService.downloadText(
      filename: filename,
      content: buildCsvExport(entries),
      mimeType: 'text/csv;charset=utf-8',
    );

    if (!mounted) {
      return;
    }
    _showMessage('CSV export started in your browser.');
  }

  Future<void> _backupJson() async {
    final entries = widget.repository.entries;
    if (entries.isEmpty) {
      _showMessage('There is no local data to back up yet.');
      return;
    }

    final filename =
        'fitness-backup-${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    await WebFileService.downloadText(
      filename: filename,
      content: buildJsonBackup(entries),
      mimeType: 'application/json;charset=utf-8',
    );

    if (!mounted) {
      return;
    }
    _showMessage('JSON backup download started.');
  }

  Future<void> _restoreJson() async {
    final rawBackup = await WebFileService.pickTextFile();
    if (rawBackup == null) {
      _showMessage('Restore canceled.');
      return;
    }

    late final List<FitnessEntry> restoredEntries;
    try {
      restoredEntries = parseJsonBackup(rawBackup);
    } catch (_) {
      _showMessage('That backup file could not be read.');
      return;
    }

    if (!mounted) {
      return;
    }

    final shouldReplace = await _showConfirmationDialog(
      title: 'Restore backup?',
      message:
          'This will replace the current on-device data with ${restoredEntries.length} restored entries.',
      confirmLabel: 'Restore',
    );
    if (!shouldReplace) {
      return;
    }

    await widget.repository.replaceAll(restoredEntries);
    if (!mounted) {
      return;
    }

    setState(() {
      _preset = ReportPreset.halfYear;
      _customRange = null;
    });
    _showMessage('Backup restored successfully.');
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final fallbackRange =
        _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: fallbackRange,
      helpText: 'Custom report range',
    );

    if (pickedRange == null || !mounted) {
      return;
    }

    setState(() {
      _preset = ReportPreset.custom;
      _customRange = DateTimeRange(
        start: FitnessEntry.normalizedDate(pickedRange.start),
        end: FitnessEntry.normalizedDate(pickedRange.end),
      );
    });
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 1080;

    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final entries = widget.repository.entries;
        final reportRange = _resolveRange(entries);
        final filteredEntries = _filterEntries(entries, reportRange);

        final pages = <Widget>[
          HomePage(
            repository: widget.repository,
            onHeaderActionSelected: _handleHeaderAction,
            onOpenDashboard: () {
              setState(() => _selectedTab = AppTab.dashboard);
            },
            onShowMessage: _showMessage,
          ),
          DashboardPage(
            allEntries: entries,
            filteredEntries: filteredEntries,
            reportRange: reportRange,
            preset: _preset,
            onPresetSelected: (preset) async {
              if (preset == ReportPreset.custom) {
                await _pickCustomRange();
                return;
              }
              setState(() {
                _preset = preset;
              });
            },
            onPickCustomRange: _pickCustomRange,
            onHeaderActionSelected: _handleHeaderAction,
          ),
        ];

        final navigationLabels = const <(IconData, String)>[
          (Icons.edit_note_rounded, 'Home'),
          (Icons.insights_rounded, 'Dashboard'),
        ];

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4F1E8), Color(0xFFE9F3EC), Color(0xFFF9EFE2)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -30,
                child: _GlowOrb(
                  size: 240,
                  color: const Color(0xFFF5A36C).withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                top: 120,
                left: -60,
                child: _GlowOrb(
                  size: 220,
                  color: const Color(0xFF84C8A4).withValues(alpha: 0.20),
                ),
              ),
              Positioned.fill(
                child: useRail
                    ? Scaffold(
                        backgroundColor: Colors.transparent,
                        body: SafeArea(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  6,
                                  18,
                                ),
                                child: _RailNavigation(
                                  selectedTab: _selectedTab,
                                  items: navigationLabels,
                                  onSelected: (index) {
                                    setState(() {
                                      _selectedTab = AppTab.values[index];
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  child: KeyedSubtree(
                                    key: ValueKey(_selectedTab),
                                    child: pages[_selectedTab.index],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Scaffold(
                        backgroundColor: Colors.transparent,
                        extendBody: true,
                        body: SafeArea(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: KeyedSubtree(
                              key: ValueKey(_selectedTab),
                              child: pages[_selectedTab.index],
                            ),
                          ),
                        ),
                        bottomNavigationBar: NavigationBar(
                          selectedIndex: _selectedTab.index,
                          destinations: navigationLabels
                              .map(
                                (item) => NavigationDestination(
                                  icon: Icon(item.$1),
                                  label: item.$2,
                                ),
                              )
                              .toList(growable: false),
                          onDestinationSelected: (index) {
                            setState(() {
                              _selectedTab = AppTab.values[index];
                            });
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.onHeaderActionSelected,
    required this.onOpenDashboard,
    required this.onShowMessage,
  });

  final FitnessRepository repository;
  final Future<void> Function(HeaderAction action) onHeaderActionSelected;
  final VoidCallback onOpenDashboard;
  final void Function(String message) onShowMessage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _neckController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  final List<_MealDraft> _mealDrafts = <_MealDraft>[];
  final List<_ExerciseDraft> _exerciseDrafts = <_ExerciseDraft>[];

  DateTime _selectedDate = FitnessEntry.normalizedDate(DateTime.now());
  String? _editingEntryId;

  @override
  void initState() {
    super.initState();
    _mealDrafts.add(_createMealDraft());
    _exerciseDrafts.add(_ExerciseDraft());
    _attachListeners();
    _resetForm(prefillHeight: true);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editingEntryId == null &&
        _heightController.text.trim().isEmpty &&
        widget.repository.latestEntry?.heightCm != null) {
      _heightController.text = widget.repository.latestEntry!.heightCm!
          .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _waistController.dispose();
    _neckController.dispose();
    _heightController.dispose();
    for (final draft in _mealDrafts) {
      draft.dispose();
    }
    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _attachListeners() {
    for (final controller in <TextEditingController>[
      _weightController,
      _durationController,
      _notesController,
      _waistController,
      _neckController,
      _heightController,
    ]) {
      controller.addListener(_triggerRebuild);
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

    _weightController.clear();
    _durationController.clear();
    _notesController.clear();
    _waistController.clear();
    _neckController.clear();
    _heightController.text = prefillHeight && latestEntry?.heightCm != null
        ? latestEntry!.heightCm!.toStringAsFixed(0)
        : '';

    for (final draft in _mealDrafts) {
      draft.dispose();
    }
    _mealDrafts
      ..clear()
      ..add(_createMealDraft());

    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    _exerciseDrafts
      ..clear()
      ..add(_ExerciseDraft());

    if (mounted) {
      setState(() {});
    }
  }

  void _loadEntry(FitnessEntry entry) {
    _editingEntryId = entry.id;
    _selectedDate = entry.date;
    _weightController.text = _formatControllerValue(entry.weightKg);
    _durationController.text = entry.workoutDurationMinutes?.toString() ?? '';
    _notesController.text = entry.notes;
    _waistController.text = _formatControllerValue(entry.waistCm);
    _neckController.text = _formatControllerValue(entry.neckCm);
    _heightController.text = _formatControllerValue(entry.heightCm);

    for (final draft in _mealDrafts) {
      draft.dispose();
    }
    _mealDrafts
      ..clear()
      ..addAll(
        entry.meals.isEmpty
            ? <_MealDraft>[_createMealDraft()]
            : entry.meals
                  .map((meal) => _createMealDraft(meal))
                  .toList(growable: false),
      );

    for (final draft in _exerciseDrafts) {
      draft.dispose();
    }
    _exerciseDrafts
      ..clear()
      ..addAll(
        entry.exercises.isEmpty
            ? <_ExerciseDraft>[_ExerciseDraft()]
            : entry.exercises
                  .map((exercise) => _ExerciseDraft.fromExercise(exercise))
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
    if (!_hasMeaningfulData) {
      widget.onShowMessage(
        'Add at least one metric, meal, note, or workout before saving.',
      );
      return;
    }

    final meals = _mealDrafts
        .map((draft) => draft.toMeal())
        .where((meal) => meal.isMeaningful)
        .toList(growable: false);
    final totalCalories = meals
        .map((meal) => meal.calories)
        .whereType<int>()
        .fold<int>(0, (running, value) => running + value);
    final totalProtein = meals
        .map((meal) => meal.proteinGrams)
        .whereType<double>()
        .fold<double>(0, (running, value) => running + value);
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

    final entry = FitnessEntry(
      id: FitnessEntry.idForDate(_selectedDate),
      date: _selectedDate,
      weightKg: _parseDouble(_weightController),
      calories: meals.any((meal) => meal.calories != null)
          ? totalCalories
          : null,
      proteinGrams: meals.any((meal) => meal.proteinGrams != null)
          ? double.parse(totalProtein.toStringAsFixed(1))
          : null,
      meals: meals,
      exercises: exercises,
      workoutDurationMinutes: _parseInt(_durationController),
      notes: _notesController.text.trim(),
      waistCm: waistCm,
      neckCm: neckCm,
      heightCm: heightCm,
      bodyFatPercentage: bodyFat,
    );

    await widget.repository.saveEntry(entry, previousId: _editingEntryId);
    if (!mounted) {
      return;
    }

    _editingEntryId = entry.id;
    setState(() {});
    widget.onShowMessage(
      'Saved your ${DateFormat('MMM d').format(entry.date)} entry locally on this device.',
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
        _mealDrafts.any((draft) => draft.toMeal().isMeaningful) ||
        _parseInt(_durationController) != null ||
        _notesController.text.trim().isNotEmpty ||
        _parseDouble(_waistController) != null ||
        _parseDouble(_neckController) != null ||
        _parseDouble(_heightController) != null ||
        _exerciseDrafts.any((draft) => draft.toExercise().isMeaningful);
  }

  _MealDraft _createMealDraft([MealEntry? meal]) {
    final draft = meal == null ? _MealDraft() : _MealDraft.fromMeal(meal);
    for (final controller in <TextEditingController>[
      draft.nameController,
      draft.foodsController,
      draft.caloriesController,
      draft.proteinController,
    ]) {
      controller.addListener(_triggerRebuild);
    }
    return draft;
  }

  int? get _dailyMealCalories {
    final values = _mealDrafts
        .map((draft) => draft.toMeal().calories)
        .whereType<int>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.fold<int>(0, (running, value) => running + value);
  }

  double? get _dailyMealProtein {
    final values = _mealDrafts
        .map((draft) => draft.toMeal().proteinGrams)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.fold<double>(0, (running, value) => running + value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestEntry = widget.repository.latestEntry;
    final existingEntry = widget.repository.entryForDate(_selectedDate);
    final bodyFat = _derivedBodyFat;
    final dailyMealCalories = _dailyMealCalories;
    final dailyMealProtein = _dailyMealProtein;
    final recentEntries = widget.repository.entries.reversed.take(7).toList();

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'LiftLedger',
              subtitle:
                  'Personal, local-only fitness tracking built for offline use on your iPhone home screen.',
              badge: 'No login',
              actionButton: PopupMenuButton<HeaderAction>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: widget.onHeaderActionSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: HeaderAction.exportCsv,
                    child: Text('Export CSV'),
                  ),
                  PopupMenuItem(
                    value: HeaderAction.backupJson,
                    child: Text('Backup JSON'),
                  ),
                  PopupMenuItem(
                    value: HeaderAction.restoreJson,
                    child: Text('Restore JSON'),
                  ),
                ],
                child: const _HeaderMenuButton(label: 'Data tools'),
              ),
            ),
            const SizedBox(height: 18),
            _HeroCard(
              title: _editingEntryId == null
                  ? 'Today\'s entry'
                  : 'Editing saved entry',
              eyebrow: _editingEntryId == null
                  ? 'Home / Data entry'
                  : 'Editing mode',
              description: latestEntry == null
                  ? 'Start with your weight, meal-by-meal nutrition, and training details. Everything stays on-device in browser storage.'
                  : 'Latest log: ${DateFormat('MMM d, yyyy').format(latestEntry.date)}. Body fat uses the US Navy male formula from waist, neck, and height.',
              metrics: [
                _HeroMetric(
                  label: 'Latest weight',
                  value: latestEntry?.weightKg != null
                      ? '${latestEntry!.weightKg!.toStringAsFixed(1)} kg'
                      : '--',
                ),
                _HeroMetric(
                  label: 'Latest calories',
                  value: latestEntry?.totalCalories != null
                      ? '${latestEntry!.totalCalories} kcal'
                      : '--',
                ),
                _HeroMetric(
                  label: 'Current body fat',
                  value: latestEntry?.bodyFatPercentage != null
                      ? '${latestEntry!.bodyFatPercentage!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 1080;
                final mainContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Daily snapshot',
                      subtitle:
                          'One saved log per date. Saving the same day updates that day\'s record.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DateSelector(
                            date: _selectedDate,
                            onTap: _pickEntryDate,
                          ),
                          if (existingEntry != null &&
                              _editingEntryId != existingEntry.id)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'A saved entry already exists for this date.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF4B5B4A),
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _loadEntry(existingEntry),
                                    child: const Text('Load it'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          _TwoColumnFields(
                            left: _NumberField(
                              controller: _weightController,
                              label: 'Weight (kg)',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            right: _NumberField(
                              controller: _heightController,
                              label: 'Height (cm)',
                              icon: Icons.height_rounded,
                              helperText: 'Used for body fat formula.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: const Color(0xFFF4F7F2),
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _NutritionSummaryChip(
                                  label: 'Meals today',
                                  value: _mealDrafts
                                      .where(
                                        (draft) => draft.toMeal().isMeaningful,
                                      )
                                      .length
                                      .toString(),
                                  icon: Icons.restaurant_menu_rounded,
                                ),
                                _NutritionSummaryChip(
                                  label: 'Daily calories',
                                  value: dailyMealCalories != null
                                      ? '$dailyMealCalories kcal'
                                      : '--',
                                  icon: Icons.local_fire_department_outlined,
                                ),
                                _NutritionSummaryChip(
                                  label: 'Daily protein',
                                  value: dailyMealProtein != null
                                      ? '${dailyMealProtein.toStringAsFixed(1)} g'
                                      : '--',
                                  icon: Icons.egg_alt_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Meals and notes',
                      subtitle:
                          'Enter foods plus calories and protein for each meal. Daily totals below feed the dashboard averages and charts.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (
                            var index = 0;
                            index < _mealDrafts.length;
                            index++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _mealDrafts.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _MealEditorCard(
                                index: index,
                                draft: _mealDrafts[index],
                                canRemove: _mealDrafts.length > 1,
                                onRemove: () {
                                  final removed = _mealDrafts.removeAt(index);
                                  removed.dispose();
                                  setState(() {});
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _mealDrafts.add(_createMealDraft());
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Add meal'),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              hintText:
                                  'Recovery, stress, sleep quality, hunger, steps, or anything else worth remembering.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Workout',
                      subtitle:
                          'Track one session with multiple exercises. Leave blank on rest days.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NumberField(
                            controller: _durationController,
                            label: 'Workout duration (min)',
                            icon: Icons.timer_outlined,
                            allowDecimal: false,
                          ),
                          const SizedBox(height: 16),
                          for (
                            var index = 0;
                            index < _exerciseDrafts.length;
                            index++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _exerciseDrafts.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _ExerciseEditorCard(
                                index: index,
                                draft: _exerciseDrafts[index],
                                canRemove: _exerciseDrafts.length > 1,
                                onRemove: () {
                                  final removed = _exerciseDrafts.removeAt(
                                    index,
                                  );
                                  removed.dispose();
                                  setState(() {});
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _exerciseDrafts.add(_ExerciseDraft());
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Add exercise'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Measurements',
                      subtitle:
                          'Waist and neck are typically weekly. Body fat is calculated automatically from those plus height.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: const Color(0xFF123826),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Derived body fat %',
                                  style: TextStyle(
                                    color: Color(0xFFB9DCC7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  bodyFat == null
                                      ? '--'
                                      : '${bodyFat.toStringAsFixed(1)}%',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'US Navy male formula: waist, neck, and height.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFE6F1EA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _saveEntry,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            _editingEntryId == null
                                ? 'Save entry'
                                : 'Update entry',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _resetForm(prefillHeight: true),
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('New blank entry'),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.onOpenDashboard,
                          icon: const Icon(Icons.insights_rounded),
                          label: const Text('Open dashboard'),
                        ),
                      ],
                    ),
                  ],
                );

                final sideContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Data tools',
                      subtitle:
                          'For long-term retention on iPhone, keep periodic JSON backups in addition to local storage.',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ToolButton(
                            label: 'Export CSV',
                            icon: Icons.table_chart_outlined,
                            onTap: () => widget.onHeaderActionSelected(
                              HeaderAction.exportCsv,
                            ),
                          ),
                          _ToolButton(
                            label: 'Backup JSON',
                            icon: Icons.download_for_offline_outlined,
                            onTap: () => widget.onHeaderActionSelected(
                              HeaderAction.backupJson,
                            ),
                          ),
                          _ToolButton(
                            label: 'Restore JSON',
                            icon: Icons.upload_file_outlined,
                            onTap: () => widget.onHeaderActionSelected(
                              HeaderAction.restoreJson,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Recent logs',
                      subtitle: recentEntries.isEmpty
                          ? 'Your saved entries will show up here.'
                          : 'Tap a day to edit or remove it.',
                      child: recentEntries.isEmpty
                          ? const _EmptyState(
                              title: 'No local entries yet',
                              subtitle:
                                  'Save your first day to start building trends and reports.',
                            )
                          : Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < recentEntries.length;
                                  index++
                                )
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == recentEntries.length - 1
                                          ? 0
                                          : 12,
                                    ),
                                    child: _RecentEntryTile(
                                      entry: recentEntries[index],
                                      onEdit: () =>
                                          _loadEntry(recentEntries[index]),
                                      onDelete: () =>
                                          _deleteEntry(recentEntries[index]),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                );

                if (!wideLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mainContent,
                      const SizedBox(height: 16),
                      sideContent,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: mainContent),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: sideContent),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
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

  double? _parseDouble(TextEditingController controller) {
    final sanitized = controller.text.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) {
      return null;
    }
    return double.tryParse(sanitized);
  }

  int? _parseInt(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  String _formatControllerValue(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.allEntries,
    required this.filteredEntries,
    required this.reportRange,
    required this.preset,
    required this.onPresetSelected,
    required this.onPickCustomRange,
    required this.onHeaderActionSelected,
  });

  final List<FitnessEntry> allEntries;
  final List<FitnessEntry> filteredEntries;
  final DateTimeRange reportRange;
  final ReportPreset preset;
  final Future<void> Function(ReportPreset preset) onPresetSelected;
  final Future<void> Function() onPickCustomRange;
  final Future<void> Function(HeaderAction action) onHeaderActionSelected;

  @override
  Widget build(BuildContext context) {
    final overallMetrics = buildDashboardMetrics(allEntries);
    final reportMetrics = buildDashboardMetrics(filteredEntries);
    final latestEntry = allEntries.isEmpty ? null : allEntries.last;
    final dateFormat = DateFormat('MMM d');

    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'Dashboard',
              subtitle:
                  'Read trends across weight, nutrition, measurements, and training from local on-device data.',
              badge: _presetLabel(preset),
              actionButton: PopupMenuButton<HeaderAction>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: onHeaderActionSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: HeaderAction.exportCsv,
                    child: Text('Export CSV'),
                  ),
                  PopupMenuItem(
                    value: HeaderAction.backupJson,
                    child: Text('Backup JSON'),
                  ),
                  PopupMenuItem(
                    value: HeaderAction.restoreJson,
                    child: Text('Restore JSON'),
                  ),
                ],
                child: const _HeaderMenuButton(label: 'Tools'),
              ),
            ),
            const SizedBox(height: 18),
            _HeroCard(
              eyebrow: 'Dashboard / Reports',
              title: latestEntry == null
                  ? 'Waiting on your first saved day'
                  : 'Current snapshot',
              description: latestEntry == null
                  ? 'Once you save entries, this page will chart weight, body fat, meal-based calories and protein, and workout frequency fully offline.'
                  : 'Latest log from ${DateFormat('MMM d, yyyy').format(latestEntry.date)}. Reports below follow the selected date range.',
              metrics: [
                _HeroMetric(
                  label: 'Current weight',
                  value: _metricNumber(
                    overallMetrics.currentWeight,
                    suffix: ' kg',
                  ),
                ),
                _HeroMetric(
                  label: 'Current body fat',
                  value: _metricNumber(
                    overallMetrics.currentBodyFat,
                    suffix: '%',
                  ),
                ),
                _HeroMetric(
                  label: 'Range',
                  value:
                      '${dateFormat.format(reportRange.start)} - ${dateFormat.format(reportRange.end)}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Reports',
              subtitle:
                  'Filter summaries and charts by preset windows or a custom date range.',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final presetOption in ReportPreset.values)
                    ChoiceChip(
                      label: Text(_presetLabel(presetOption)),
                      selected: preset == presetOption,
                      onSelected: (_) => onPresetSelected(presetOption),
                    ),
                  OutlinedButton.icon(
                    onPressed: onPickCustomRange,
                    icon: const Icon(Icons.date_range_rounded),
                    label: const Text('Pick custom range'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filteredEntries.isEmpty)
              const _SectionCard(
                title: 'No entries in this range',
                child: _EmptyState(
                  title: 'Nothing to chart yet',
                  subtitle:
                      'Try a wider report window or restore a backup once you have one.',
                ),
              )
            else ...[
              _MetricsGrid(
                cards: [
                  _MetricCardData(
                    title: 'Current weight',
                    value: _metricNumber(
                      reportMetrics.currentWeight,
                      suffix: ' kg',
                    ),
                    tone: MetricTone.primary,
                  ),
                  _MetricCardData(
                    title: 'Starting weight',
                    value: _metricNumber(
                      reportMetrics.startingWeight,
                      suffix: ' kg',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Total weight loss',
                    value: _signedMetric(reportMetrics.totalWeightLoss, ' kg'),
                    tone: MetricTone.positive,
                  ),
                  _MetricCardData(
                    title: 'Average weight',
                    value: _metricNumber(
                      reportMetrics.averageWeight,
                      suffix: ' kg',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Lowest weight',
                    value: _metricNumber(
                      reportMetrics.lowestWeight,
                      suffix: ' kg',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Highest weight',
                    value: _metricNumber(
                      reportMetrics.highestWeight,
                      suffix: ' kg',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Current body fat',
                    value: _metricNumber(
                      reportMetrics.currentBodyFat,
                      suffix: '%',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Body fat change',
                    value: _signedMetric(reportMetrics.bodyFatChange, '%'),
                    tone: MetricTone.positive,
                    invertTone: true,
                  ),
                  _MetricCardData(
                    title: 'Waist change',
                    value: _signedMetric(reportMetrics.waistChange, ' cm'),
                    tone: MetricTone.positive,
                    invertTone: true,
                  ),
                  _MetricCardData(
                    title: 'Average calories',
                    value: _metricNumber(
                      reportMetrics.averageCalories,
                      digits: 0,
                    ),
                  ),
                  _MetricCardData(
                    title: 'Average protein',
                    value: _metricNumber(
                      reportMetrics.averageProtein,
                      suffix: ' g',
                    ),
                  ),
                  _MetricCardData(
                    title: 'Workout days',
                    value: reportMetrics.totalWorkoutDays.toString(),
                  ),
                  _MetricCardData(
                    title: 'Total sets',
                    value: reportMetrics.totalSets.toString(),
                  ),
                  _MetricCardData(
                    title: 'Workout volume',
                    value:
                        '${NumberFormat.compact().format(reportMetrics.workoutVolume)} kg',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth >= 1000
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: chartWidth,
                        child: _TrendChartCard(
                          title: 'Weight trend',
                          color: const Color(0xFF1D7A57),
                          suffix: ' kg',
                          points: _buildTrendPoints(
                            filteredEntries,
                            (entry) => entry.weightKg,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: _TrendChartCard(
                          title: 'Body fat trend',
                          color: const Color(0xFFF28452),
                          suffix: '%',
                          points: _buildTrendPoints(
                            filteredEntries,
                            (entry) => entry.bodyFatPercentage,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: _TrendChartCard(
                          title: 'Waist trend',
                          color: const Color(0xFF376996),
                          suffix: ' cm',
                          points: _buildTrendPoints(
                            filteredEntries,
                            (entry) => entry.waistCm,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: _TrendChartCard(
                          title: 'Calories trend',
                          color: const Color(0xFFE2AA2B),
                          suffix: '',
                          digits: 0,
                          points: _buildTrendPoints(
                            filteredEntries,
                            (entry) => entry.totalCalories?.toDouble(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: _TrendChartCard(
                          title: 'Protein trend',
                          color: const Color(0xFF8B5CF6),
                          suffix: ' g',
                          digits: 0,
                          points: _buildTrendPoints(
                            filteredEntries,
                            (entry) => entry.totalProteinGrams,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: chartWidth,
                        child: _WorkoutFrequencyChartCard(
                          title: 'Workout frequency',
                          buckets: buildWorkoutFrequency(filteredEntries),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<_TrendPoint> _buildTrendPoints(
    List<FitnessEntry> entries,
    double? Function(FitnessEntry entry) selector,
  ) {
    return entries
        .map((entry) {
          final value = selector(entry);
          return value == null ? null : _TrendPoint(entry.date, value);
        })
        .whereType<_TrendPoint>()
        .toList(growable: false);
  }
}

class _MealDraft {
  _MealDraft({
    String name = '',
    String foods = '',
    String calories = '',
    String protein = '',
  }) : nameController = TextEditingController(text: name),
       foodsController = TextEditingController(text: foods),
       caloriesController = TextEditingController(text: calories),
       proteinController = TextEditingController(text: protein);

  factory _MealDraft.fromMeal(MealEntry meal) {
    return _MealDraft(
      name: meal.name,
      foods: meal.foods,
      calories: meal.calories?.toString() ?? '',
      protein: meal.proteinGrams == null
          ? ''
          : meal.proteinGrams == meal.proteinGrams!.roundToDouble()
          ? meal.proteinGrams!.toStringAsFixed(0)
          : meal.proteinGrams!.toStringAsFixed(1),
    );
  }

  final TextEditingController nameController;
  final TextEditingController foodsController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;

  MealEntry toMeal() {
    return MealEntry(
      name: nameController.text.trim(),
      foods: foodsController.text.trim(),
      calories: int.tryParse(caloriesController.text.trim()),
      proteinGrams: double.tryParse(
        proteinController.text.replaceAll(',', '.').trim(),
      ),
    );
  }

  void dispose() {
    nameController.dispose();
    foodsController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    String workoutType = '',
    String exerciseName = '',
    String sets = '',
    String reps = '',
    String weightKg = '',
  }) : workoutTypeController = TextEditingController(text: workoutType),
       exerciseNameController = TextEditingController(text: exerciseName),
       setsController = TextEditingController(text: sets),
       repsController = TextEditingController(text: reps),
       weightController = TextEditingController(text: weightKg);

  factory _ExerciseDraft.fromExercise(WorkoutExercise exercise) {
    return _ExerciseDraft(
      workoutType: exercise.workoutType,
      exerciseName: exercise.exerciseName,
      sets: exercise.sets.toString(),
      reps: exercise.reps.toString(),
      weightKg: exercise.weightKg == exercise.weightKg.roundToDouble()
          ? exercise.weightKg.toStringAsFixed(0)
          : exercise.weightKg.toStringAsFixed(1),
    );
  }

  final TextEditingController workoutTypeController;
  final TextEditingController exerciseNameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;

  WorkoutExercise toExercise() {
    return WorkoutExercise(
      workoutType: workoutTypeController.text.trim(),
      exerciseName: exerciseNameController.text.trim(),
      sets: int.tryParse(setsController.text.trim()) ?? 0,
      reps: int.tryParse(repsController.text.trim()) ?? 0,
      weightKg:
          double.tryParse(weightController.text.replaceAll(',', '.').trim()) ??
          0,
    );
  }

  void dispose() {
    workoutTypeController.dispose();
    exerciseNameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.actionButton,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Widget actionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withValues(alpha: 0.74),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeaderText(
                      theme: theme,
                      badge: badge,
                      title: title,
                      subtitle: subtitle,
                    ),
                    const SizedBox(height: 16),
                    actionButton,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PageHeaderText(
                        theme: theme,
                        badge: badge,
                        title: title,
                        subtitle: subtitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    actionButton,
                  ],
                ),
        );
      },
    );
  }
}

class _PageHeaderText extends StatelessWidget {
  const _PageHeaderText({
    required this.theme,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final ThemeData theme;
  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFF123826),
          ),
          child: Text(
            badge,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: const Color(0xFF13231A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF526152),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF123826),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.tune_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _HeroMetric {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.metrics,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<_HeroMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123826), Color(0xFF245541), Color(0xFF1E6F7A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E123826),
            blurRadius: 22,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFB7DDC4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFE5F1EA),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map(
                  (metric) => Container(
                    width: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFB9DCC7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metric.value,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF13231A),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF617260),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.88),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, MMM d, yyyy').format(date)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;

        if (stacked) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.helperText,
    this.allowDecimal = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? helperText;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _NutritionSummaryChip extends StatelessWidget {
  const _NutritionSummaryChip({
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
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D7A57)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF617260)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealEditorCard extends StatelessWidget {
  const _MealEditorCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _MealDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
                'Meal ${index + 1}',
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
          _TwoColumnFields(
            left: TextField(
              controller: draft.nameController,
              decoration: const InputDecoration(
                labelText: 'Meal name',
                hintText: 'Breakfast, lunch, dinner...',
                prefixIcon: Icon(Icons.breakfast_dining_rounded),
              ),
            ),
            right: TextField(
              controller: draft.foodsController,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Food / items',
                hintText: 'Oats, banana, whey protein',
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TwoColumnFields(
            left: TextField(
              controller: draft.caloriesController,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: const InputDecoration(
                labelText: 'Calories',
                prefixIcon: Icon(Icons.local_fire_department_outlined),
              ),
            ),
            right: TextField(
              controller: draft.proteinController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Protein (g)',
                prefixIcon: Icon(Icons.egg_alt_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseEditorCard extends StatelessWidget {
  const _ExerciseEditorCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _ExerciseDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF5F7F3),
      ),
      child: Column(
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
          _TwoColumnFields(
            left: TextField(
              controller: draft.workoutTypeController,
              decoration: const InputDecoration(
                labelText: 'Workout type',
                prefixIcon: Icon(Icons.fitness_center_rounded),
              ),
            ),
            right: TextField(
              controller: draft.exerciseNameController,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                prefixIcon: Icon(Icons.sports_gymnastics_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.setsController,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.repsController,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    prefixIcon: Icon(Icons.countertops_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FitnessEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  DateFormat('EEE, MMM d').format(entry.date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                label: entry.weightKg != null
                    ? '${entry.weightKg!.toStringAsFixed(1)} kg'
                    : 'No weight',
              ),
              _MiniChip(
                label: entry.totalCalories != null
                    ? '${entry.totalCalories} kcal'
                    : 'No calories',
              ),
              _MiniChip(
                label: entry.totalProteinGrams != null
                    ? '${entry.totalProteinGrams!.toStringAsFixed(1)} g protein'
                    : 'No protein',
              ),
              _MiniChip(
                label: entry.hasWorkout
                    ? '${entry.totalSets} sets'
                    : 'Rest / no workout',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.cards});

  final List<_MetricCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 820
            ? 3
            : 2;
        final cardWidth =
            (constraints.maxWidth - ((columnCount - 1) * 12)) / columnCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: _MetricCard(card: card),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

enum MetricTone { neutral, primary, positive }

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    this.tone = MetricTone.neutral,
    this.invertTone = false,
  });

  final String title;
  final String value;
  final MetricTone tone;
  final bool invertTone;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.card});

  final _MetricCardData card;

  @override
  Widget build(BuildContext context) {
    final palette = switch (card.tone) {
      MetricTone.primary => (
        background: const Color(0xFF123826),
        foreground: Colors.white,
        accent: const Color(0xFFB7DDC4),
      ),
      MetricTone.positive => (
        background: card.invertTone
            ? const Color(0xFFF7E6D8)
            : const Color(0xFFE3F4E8),
        foreground: const Color(0xFF13231A),
        accent: card.invertTone
            ? const Color(0xFF9A4A16)
            : const Color(0xFF1F6E4A),
      ),
      MetricTone.neutral => (
        background: Colors.white.withValues(alpha: 0.88),
        foreground: const Color(0xFF13231A),
        accent: const Color(0xFF627161),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  const _TrendPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({
    required this.title,
    required this.points,
    required this.color,
    required this.suffix,
    this.digits = 1,
  });

  final String title;
  final List<_TrendPoint> points;
  final Color color;
  final String suffix;
  final int digits;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _SectionCard(
        title: title,
        child: const SizedBox(
          height: 240,
          child: _EmptyState(
            title: 'No data points',
            subtitle: 'Save more entries in this range to see the trend.',
          ),
        ),
      );
    }

    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList(growable: false);
    final minY = points.map((point) => point.value).reduce(math.min);
    final maxY = points.map((point) => point.value).reduce(math.max);
    final interval = _axisInterval(minY, maxY);

    return _SectionCard(
      title: title,
      subtitle: '${points.length} points in selected range',
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(spots.length - 1, 1).toDouble(),
            minY: minY == maxY ? minY - 1 : minY - interval,
            maxY: minY == maxY ? maxY + 1 : maxY + interval,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .map((spot) {
                        final point = points[spot.x.toInt()];
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(point.date)}\n${point.value.toStringAsFixed(digits)}$suffix',
                          const TextStyle(
                            color: Color(0xFF13231A),
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      })
                      .toList(growable: false);
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: color.withValues(alpha: 0.12), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: math.max((points.length - 1) / 2, 1).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM d').format(points[index].date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF617260),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(digits),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF617260),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3.4,
                color: color,
                dotData: FlDotData(
                  show: points.length < 10,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutFrequencyChartCard extends StatelessWidget {
  const _WorkoutFrequencyChartCard({
    required this.title,
    required this.buckets,
  });

  final String title;
  final List<WeeklyWorkoutBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return _SectionCard(
        title: title,
        child: const SizedBox(
          height: 240,
          child: _EmptyState(
            title: 'No workout weeks',
            subtitle:
                'Workout frequency will appear once training sessions are logged.',
          ),
        ),
      );
    }

    final maxWorkoutDays = buckets
        .map((bucket) => bucket.workoutDays)
        .fold<int>(0, math.max);

    return _SectionCard(
      title: title,
      subtitle: 'Workout days per week bucket',
      child: SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: math.max(maxWorkoutDays.toDouble() + 1, 4),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: const Color(0xFF1D7A57).withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final bucket = buckets[group.x.toInt()];
                  return BarTooltipItem(
                    '${DateFormat('MMM d').format(bucket.weekStart)}\n${bucket.workoutDays} workout days',
                    const TextStyle(
                      color: Color(0xFF13231A),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF617260),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    final showEvery = buckets.length > 8 ? 2 : 1;
                    if (index % showEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM d').format(buckets[index].weekStart),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF617260),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: buckets
                .asMap()
                .entries
                .map(
                  (entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.workoutDays.toDouble(),
                        width: 18,
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF1D7A57), Color(0xFF58AD7C)],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _RailNavigation extends StatelessWidget {
  const _RailNavigation({
    required this.selectedTab,
    required this.items,
    required this.onSelected,
  });

  final AppTab selectedTab;
  final List<(IconData, String)> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.76),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: selectedTab.index,
        labelType: NavigationRailLabelType.all,
        indicatorColor: const Color(0x221D7A57),
        onDestinationSelected: onSelected,
        destinations: items
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.$1),
                label: Text(item.$2),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 40,
            color: Color(0xFF617260),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF617260),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _metricNumber(double? value, {String suffix = '', int digits = 1}) {
  if (value == null) {
    return '--';
  }
  return '${value.toStringAsFixed(digits)}$suffix';
}

String _signedMetric(double? value, String suffix) {
  if (value == null) {
    return '--';
  }
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}$suffix';
}

double _axisInterval(double minY, double maxY) {
  final spread = (maxY - minY).abs();
  if (spread <= 2) {
    return 0.5;
  }
  if (spread <= 10) {
    return 2;
  }
  if (spread <= 30) {
    return 5;
  }
  return 10;
}

String _presetLabel(ReportPreset preset) {
  return switch (preset) {
    ReportPreset.week => 'This week',
    ReportPreset.month => 'This month',
    ReportPreset.quarter => 'Last 3 months',
    ReportPreset.halfYear => 'Last 6 months',
    ReportPreset.custom => 'Custom range',
  };
}
