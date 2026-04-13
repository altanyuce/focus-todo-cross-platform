import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';

List<Task> getOutboundTasks(
  List<Task> tasks,
  List<TaskSyncMetadata> syncMetadata,
) {
  final pendingTaskIds = syncMetadata
      .where(
        (TaskSyncMetadata item) =>
            item.syncStatus == TaskSyncStatus.pendingUpsert ||
            item.syncStatus == TaskSyncStatus.pendingDelete,
      )
      .map((TaskSyncMetadata item) => item.taskId)
      .toSet();

  return tasks
      .where((Task task) => pendingTaskIds.contains(task.id))
      .toList(growable: false);
}
