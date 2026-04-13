import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'tasks_ui_state.dart';

class TasksState {
  const TasksState({
    required this.deviceId,
    required this.tasks,
    required this.syncMetadata,
    required this.ui,
  });

  final String deviceId;
  final List<Task> tasks;
  final List<TaskSyncMetadata> syncMetadata;
  final TasksUiState ui;

  TasksState copyWith({
    String? deviceId,
    List<Task>? tasks,
    List<TaskSyncMetadata>? syncMetadata,
    TasksUiState? ui,
  }) {
    return TasksState(
      deviceId: deviceId ?? this.deviceId,
      tasks: tasks ?? this.tasks,
      syncMetadata: syncMetadata ?? this.syncMetadata,
      ui: ui ?? this.ui,
    );
  }
}
