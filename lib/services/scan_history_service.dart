import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_history_entry.dart';

/// Persists completed scans on-device (SharedPreferences) so the user can
/// revisit past 3D models after leaving the result screen.
class ScanHistoryService {
  ScanHistoryService._();

  static const _storageKey = 'scan_history_v1';

  /// Most recent scan first.
  static Future<List<ScanHistoryEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    return raw.map((e) => ScanHistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList().reversed.toList();
  }

  static Future<void> add(ScanHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_storageKey, raw);
  }

  static Future<void> remove(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    raw.removeWhere((e) => (jsonDecode(e) as Map<String, dynamic>)['task_id'] == taskId);
    await prefs.setStringList(_storageKey, raw);
  }
}
