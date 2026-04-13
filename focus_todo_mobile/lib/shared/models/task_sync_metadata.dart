enum TaskSyncStatus { pendingUpsert, pendingDelete, synced, error }

extension TaskSyncStatusX on TaskSyncStatus {
  String get storageValue {
    switch (this) {
      case TaskSyncStatus.pendingUpsert:
        return 'pending-upsert';
      case TaskSyncStatus.pendingDelete:
        return 'pending-delete';
      case TaskSyncStatus.synced:
        return 'synced';
      case TaskSyncStatus.error:
        return 'error';
    }
  }

  static TaskSyncStatus fromStorage(String? value) {
    switch (value) {
      case 'pending-delete':
        return TaskSyncStatus.pendingDelete;
      case 'synced':
        return TaskSyncStatus.synced;
      case 'error':
        return TaskSyncStatus.error;
      case 'pending-upsert':
      default:
        return TaskSyncStatus.pendingUpsert;
    }
  }
}

class TaskSyncMetadata {
  const TaskSyncMetadata({
    required this.taskId,
    required this.ownerUserId,
    required this.syncStatus,
    required this.lastSyncedAt,
    required this.lastKnownServerUpdatedAt,
    required this.lastSyncError,
  });

  final String taskId;
  final String? ownerUserId;
  final TaskSyncStatus syncStatus;
  final String? lastSyncedAt;
  final String? lastKnownServerUpdatedAt;
  final String? lastSyncError;

  TaskSyncMetadata copyWith({
    String? taskId,
    String? ownerUserId,
    bool clearOwnerUserId = false,
    TaskSyncStatus? syncStatus,
    String? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? lastKnownServerUpdatedAt,
    bool clearLastKnownServerUpdatedAt = false,
    String? lastSyncError,
    bool clearLastSyncError = false,
  }) {
    return TaskSyncMetadata(
      taskId: taskId ?? this.taskId,
      ownerUserId: clearOwnerUserId ? null : (ownerUserId ?? this.ownerUserId),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      lastKnownServerUpdatedAt: clearLastKnownServerUpdatedAt
          ? null
          : (lastKnownServerUpdatedAt ?? this.lastKnownServerUpdatedAt),
      lastSyncError: clearLastSyncError
          ? null
          : (lastSyncError ?? this.lastSyncError),
    );
  }

  factory TaskSyncMetadata.fromJson(Map<String, dynamic> json) {
    return TaskSyncMetadata(
      taskId: _stringOrEmpty(json['taskId']),
      ownerUserId: _nullableString(json['ownerUserId']),
      syncStatus: TaskSyncStatusX.fromStorage(
        _nullableString(json['syncStatus']),
      ),
      lastSyncedAt: _nullableString(json['lastSyncedAt']),
      lastKnownServerUpdatedAt: _nullableString(
        json['lastKnownServerUpdatedAt'],
      ),
      lastSyncError: _nullableString(json['lastSyncError']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'taskId': taskId,
      'ownerUserId': ownerUserId,
      'syncStatus': syncStatus.storageValue,
      'lastSyncedAt': lastSyncedAt,
      'lastKnownServerUpdatedAt': lastKnownServerUpdatedAt,
      'lastSyncError': lastSyncError,
    };
  }

  static String _stringOrEmpty(dynamic value) {
    return value is String ? value : '';
  }

  static String? _nullableString(dynamic value) {
    return value is String ? value : null;
  }
}
