import '../shared/models/task_sync_metadata.dart';

class MarkSyncedOptions {
  const MarkSyncedOptions({this.lastKnownServerUpdatedAt, this.lastSyncedAt});

  final String? lastKnownServerUpdatedAt;
  final String? lastSyncedAt;
}

TaskSyncMetadata _defaultSyncMetadata(String taskId) {
  return TaskSyncMetadata(
    taskId: taskId,
    ownerUserId: null,
    syncStatus: TaskSyncStatus.pendingUpsert,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
  );
}

List<TaskSyncMetadata> _updateMetadata(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
  TaskSyncMetadata Function(TaskSyncMetadata current) buildNext,
) {
  final existing = syncMetadata.cast<TaskSyncMetadata?>().firstWhere(
    (TaskSyncMetadata? item) => item?.taskId == taskId,
    orElse: () => null,
  );

  final next = buildNext(existing ?? _defaultSyncMetadata(taskId));

  return <TaskSyncMetadata>[
    next,
    ...syncMetadata.where((TaskSyncMetadata item) => item.taskId != taskId),
  ];
}

List<TaskSyncMetadata> markPendingUpsert(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
) {
  return _updateMetadata(
    syncMetadata,
    taskId,
    (TaskSyncMetadata current) => current.copyWith(
      syncStatus: TaskSyncStatus.pendingUpsert,
      clearLastSyncError: true,
    ),
  );
}

List<TaskSyncMetadata> markPendingDelete(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
) {
  return _updateMetadata(
    syncMetadata,
    taskId,
    (TaskSyncMetadata current) => current.copyWith(
      syncStatus: TaskSyncStatus.pendingDelete,
      clearLastSyncError: true,
    ),
  );
}

List<TaskSyncMetadata> markSynced(
  List<TaskSyncMetadata> syncMetadata,
  String taskId, {
  MarkSyncedOptions options = const MarkSyncedOptions(),
}) {
  return _updateMetadata(
    syncMetadata,
    taskId,
    (TaskSyncMetadata current) => current.copyWith(
      syncStatus: TaskSyncStatus.synced,
      lastKnownServerUpdatedAt: options.lastKnownServerUpdatedAt,
      clearLastKnownServerUpdatedAt: options.lastKnownServerUpdatedAt == null,
      lastSyncedAt: options.lastSyncedAt,
      clearLastSyncedAt: options.lastSyncedAt == null,
      clearLastSyncError: true,
    ),
  );
}

List<TaskSyncMetadata> markError(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
  String error,
) {
  return _updateMetadata(
    syncMetadata,
    taskId,
    (TaskSyncMetadata current) => current.copyWith(
      syncStatus: TaskSyncStatus.error,
      lastSyncError: error,
    ),
  );
}
