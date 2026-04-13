import '../../../../shared/models/task.dart';
import '../../../../shared/models/task_sync_metadata.dart';

class TaskDataState {
  const TaskDataState({required this.tasks, required this.syncMetadata});

  final List<Task> tasks;
  final List<TaskSyncMetadata> syncMetadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tasks': tasks.map((Task task) => task.toJson()).toList(growable: false),
      'syncMetadata': syncMetadata
          .map((TaskSyncMetadata item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory TaskDataState.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'];
    final rawSyncMetadata = json['syncMetadata'];

    return TaskDataState(
      tasks: rawTasks is List
          ? rawTasks
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (Map<dynamic, dynamic> item) => Task.fromJson(
                    item.map(
                      (dynamic key, dynamic value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList(growable: false)
          : const <Task>[],
      syncMetadata: rawSyncMetadata is List
          ? rawSyncMetadata
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (Map<dynamic, dynamic> item) => TaskSyncMetadata.fromJson(
                    item.map(
                      (dynamic key, dynamic value) =>
                          MapEntry(key.toString(), value),
                    ),
                  ),
                )
                .toList(growable: false)
          : const <TaskSyncMetadata>[],
    );
  }
}
