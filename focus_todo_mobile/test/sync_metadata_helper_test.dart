import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'package:focus_todo_mobile/sync/sync_metadata_helper.dart';

TaskSyncMetadata _metadata(String taskId) {
  return TaskSyncMetadata(
    taskId: taskId,
    ownerUserId: null,
    syncStatus: TaskSyncStatus.pendingUpsert,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
  );
}

void main() {
  group('sync metadata helper edges', () {
    test('markSynced stores server version and preserves task identity', () {
      final result = markSynced(
        <TaskSyncMetadata>[_metadata('task-1')],
        'task-1',
        options: const MarkSyncedOptions(
          lastKnownServerUpdatedAt: '2026-04-02T11:00:00.000Z',
          lastSyncedAt: '2026-04-02T11:01:00.000Z',
        ),
      );

      expect(result.single.taskId, 'task-1');
      expect(result.single.syncStatus, TaskSyncStatus.synced);
      expect(
        result.single.lastKnownServerUpdatedAt,
        '2026-04-02T11:00:00.000Z',
      );
    });
  });
}
