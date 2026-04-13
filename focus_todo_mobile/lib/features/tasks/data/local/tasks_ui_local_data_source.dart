import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/state/tasks_ui_state.dart';

class TasksUiLocalDataSource {
  static const String uiStorageKey = 'focus-todo-ui-state-v1';
  static const String legacyStorageKey = 'focus-todo-state-v1';

  Future<TasksUiState?> loadState() async {
    final preferences = await SharedPreferences.getInstance();

    try {
      final raw = preferences.getString(uiStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data = decoded['data'];
          if (data is Map) {
            return TasksUiState.fromJson(
              data.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            );
          }
        }
      }
    } catch (_) {
      /* ignore invalid persisted UI state */
    }

    try {
      final rawLegacy = preferences.getString(legacyStorageKey);
      if (rawLegacy == null || rawLegacy.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(rawLegacy);
      if (decoded is! Map) {
        return null;
      }

      final rawUi = decoded['ui'];
      if (rawUi is! Map) {
        return null;
      }

      return TasksUiState.fromJson(
        rawUi.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(TasksUiState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      uiStorageKey,
      jsonEncode(<String, dynamic>{'version': 1, 'data': state.toJson()}),
    );
  }
}
