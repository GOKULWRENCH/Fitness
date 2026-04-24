import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/fitness_entry.dart';

class FitnessRepository extends ChangeNotifier {
  FitnessRepository.persistent() : _isInMemory = false;

  FitnessRepository.memory({List<FitnessEntry> seed = const []})
    : _isInMemory = true {
    _entries
      ..addAll(seed)
      ..sort(_sortEntries);
  }

  static const String _boxName = 'fitness_daily_entries';

  final bool _isInMemory;
  final List<FitnessEntry> _entries = <FitnessEntry>[];
  Box<String>? _box;
  bool _isInitialized = false;

  List<FitnessEntry> get entries => List.unmodifiable(_entries);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (!_isInMemory) {
      Hive.init('fitness_tracker_storage');
      _box = await Hive.openBox<String>(_boxName);
      _entries
        ..clear()
        ..addAll(
          _box!.values
              .map(_decodeEntry)
              .whereType<FitnessEntry>()
              .toList(growable: false),
        )
        ..sort(_sortEntries);
    }

    _isInitialized = true;
  }

  FitnessEntry? entryForDate(DateTime date) {
    final id = FitnessEntry.idForDate(date);
    for (final entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  FitnessEntry? get latestEntry => _entries.isEmpty ? null : _entries.last;

  Future<void> saveEntry(FitnessEntry entry, {String? previousId}) async {
    final normalizedEntry = entry.copyWith(
      id: FitnessEntry.idForDate(entry.date),
      date: FitnessEntry.normalizedDate(entry.date),
    );

    if (!_isInMemory && _box == null) {
      throw StateError('FitnessRepository.initialize() must be called first.');
    }

    final removalId = previousId?.trim();
    if (removalId != null &&
        removalId.isNotEmpty &&
        removalId != normalizedEntry.id) {
      _entries.removeWhere((existing) => existing.id == removalId);
      if (!_isInMemory) {
        await _box!.delete(removalId);
      }
    }

    _entries.removeWhere((existing) => existing.id == normalizedEntry.id);
    _entries.add(normalizedEntry);
    _entries.sort(_sortEntries);

    if (!_isInMemory) {
      await _box!.put(normalizedEntry.id, jsonEncode(normalizedEntry.toJson()));
    }

    notifyListeners();
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((entry) => entry.id == entryId);
    if (!_isInMemory) {
      await _box!.delete(entryId);
    }
    notifyListeners();
  }

  Future<void> replaceAll(List<FitnessEntry> nextEntries) async {
    final normalizedEntries =
        nextEntries
            .map(
              (entry) => entry.copyWith(
                id: FitnessEntry.idForDate(entry.date),
                date: FitnessEntry.normalizedDate(entry.date),
              ),
            )
            .toList(growable: false)
          ..sort(_sortEntries);

    _entries
      ..clear()
      ..addAll(normalizedEntries);

    if (!_isInMemory) {
      final values = <String, String>{
        for (final entry in normalizedEntries)
          entry.id: jsonEncode(entry.toJson()),
      };
      await _box!.clear();
      if (values.isNotEmpty) {
        await _box!.putAll(values);
      }
    }

    notifyListeners();
  }

  FitnessEntry? _decodeEntry(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        return FitnessEntry.fromJson(decoded);
      }
      if (decoded is Map) {
        return FitnessEntry.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static int _sortEntries(FitnessEntry left, FitnessEntry right) {
    return left.date.compareTo(right.date);
  }
}
