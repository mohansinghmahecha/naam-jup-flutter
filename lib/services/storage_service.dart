// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/god.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String keyGods = 'gods_list_v1';
  static const String keyDailyCounts = 'daily_counts_v1';

  // ------------------ GODS LIST ------------------

  /// Save the list of gods to SharedPreferences
  static Future<void> saveGods(List<God> gods) async {
    final prefs = await SharedPreferences.getInstance();
    final list = gods.map((g) => g.toJson()).toList();
    await prefs.setString(keyGods, jsonEncode(list));
  }

  /// Load the saved list of gods
  static Future<List<God>> loadGods() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(keyGods);
    if (data == null) return [];
    final List decoded = jsonDecode(data) as List;
    return decoded.map((e) => God.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Clear saved gods list
  static Future<void> clearGods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyGods);
  }

  // ------------------ DAILY COUNTS ------------------

  /// Save daily counts
  /// Format:
  /// {
  ///   "2025-10-13": { "godId1": 5, "godId2": 10 },
  ///   "2025-10-12": { "godId1": 108 }
  /// }
  static Future<void> saveDailyCounts(Map<String, dynamic> dailyData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDailyCounts, jsonEncode(dailyData));
  }

  /// Load daily counts
  static Future<Map<String, dynamic>> loadDailyCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(keyDailyCounts);
    if (data == null) return {};
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Clear daily counts
  static Future<void> clearDailyCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyDailyCounts);
  }
}
