// lib/providers/god_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/god.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

final godListProvider = StateNotifierProvider<GodListNotifier, List<God>>((
  ref,
) {
  return GodListNotifier();
});

class GodListNotifier extends StateNotifier<List<God>> {
  GodListNotifier() : super([]) {
    _loadGods();
  }

  // ---------------- Load Gods ----------------
  Future<void> _loadGods() async {
    final saved = await StorageService.loadGods();
    if (saved.isNotEmpty) {
      state = saved;
    } else {
      // default sample gods
      state = [
        God(id: const Uuid().v4(), name: 'राम'),
        God(id: const Uuid().v4(), name: 'शिव'),
        God(id: const Uuid().v4(), name: 'विष्णु'),
        God(id: const Uuid().v4(), name: 'लक्ष्मी'),
      ];
      await StorageService.saveGods(state);
    }
  }

  // ---------------- Increment Count ----------------
  Future<void> incrementCount(String id) async {
    final updated =
        state.map((god) {
          if (god.id == id) {
            int newSession = god.sessionCount + 1; // unlimited
            int newTotal = god.totalCount + 1;

            _updateDailyCount(god.id); // track daily count

            return God(
              id: god.id,
              name: god.name,
              sessionCount: newSession,
              totalCount: newTotal,
            );
          }
          return god;
        }).toList();

    state = updated;
    await StorageService.saveGods(state);
  }

  // ---------------- Track Daily Count ----------------
  // Future<void> _updateDailyCount(String godId) async {
  //   final dailyCounts = await StorageService.loadDailyCounts();
  //   final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  //   // today's data or empty
  //   Map<String, dynamic> todayData =
  //       (dailyCounts[today] ?? {}) as Map<String, dynamic>;

  //   int currentCount = todayData[godId] ?? 0;
  //   todayData[godId] = currentCount + 1;

  //   dailyCounts[today] = todayData;
  //   await StorageService.saveDailyCounts(dailyCounts);
  // }

  Future<void> _updateDailyCount(String godId) async {
    // Load existing daily data
    final dailyCounts = await StorageService.loadDailyCounts();
    print("dailyCounts before update: $dailyCounts");
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Safely extract today's map
    Map<String, dynamic> todayData = {};
    final rawTodayData = dailyCounts[today];

    if (rawTodayData is Map) {
      // Safely convert all keys/values to String/dynamic
      todayData = Map<String, dynamic>.from(
        rawTodayData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    // Increment today's count for this god
    int currentCount = (todayData[godId] ?? 0) as int;
    todayData[godId] = currentCount + 1;

    // Update back into main map
    dailyCounts[today] = todayData;

    // Save updated data
    await StorageService.saveDailyCounts(dailyCounts);

    // Debug log
    print(
      '✅ Daily count updated for $godId → ${todayData[godId]} (Date: $today)',
    );
  }

  // ---------------- Manual Count Update ----------------
  Future<void> addManualCount(String godId, int count) async {
    // 1️⃣ Update god totals
    final updated =
        state.map((god) {
          if (god.id == godId) {
            return God(
              id: god.id,
              name: god.name,
              sessionCount: god.sessionCount,
              totalCount: god.totalCount + count,
            );
          }
          return god;
        }).toList();
    state = updated;
    await StorageService.saveGods(state);

    // 2️⃣ Log into daily counts for analysis
    final dailyCounts = await StorageService.loadDailyCounts();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Map<String, dynamic> todayData = {};
    final rawTodayData = dailyCounts[today];
    if (rawTodayData is Map) {
      todayData = Map<String, dynamic>.from(
        rawTodayData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    todayData[godId] = (todayData[godId] ?? 0) + count;
    dailyCounts[today] = todayData;

    await StorageService.saveDailyCounts(dailyCounts);
  }

  // ---------------- Rename God ----------------
  Future<void> renameGod(String id, String newName) async {
    final updated =
        state.map((god) {
          if (god.id == id) {
            return God(
              id: god.id,
              name: newName,
              sessionCount: god.sessionCount,
              totalCount: god.totalCount,
            );
          }
          return god;
        }).toList();
    state = updated;
    await StorageService.saveGods(state);
  }

  // ---------------- Add God ----------------
  Future<void> addGod(String name) async {
    final newGod = God(
      id: const Uuid().v4(),
      name: name,
      sessionCount: 0,
      totalCount: 0,
    );
    state = [...state, newGod];
    await StorageService.saveGods(state);
  }
}
