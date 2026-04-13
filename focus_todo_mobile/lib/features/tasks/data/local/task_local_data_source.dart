import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_data_state.dart';

class TaskLocalDataSource {
  static const String storageKey = 'focus-todo-task-data-v2';
  static const String legacyStorageKey = 'focus-todo-state-v1';

  Future<TaskDataState?> loadState() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data = decoded['data'];
          if (data is Map) {
            return TaskDataState.fromJson(
              data.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            );
          }
        }
      }
    } catch (_) {
      /* ignore invalid new-format task state */
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(legacyStorageKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final rawTasks = decoded['tasks'];

      return TaskDataState.fromJson(<String, dynamic>{
        'tasks': rawTasks,
        'syncMetadata': const <Map<String, dynamic>>[],
      });
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasPersistedState() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(storageKey) ||
        preferences.containsKey(legacyStorageKey);
  }

  Future<void> saveState(TaskDataState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(<String, dynamic>{'version': 2, 'data': state.toJson()}),
    );
  }
}
