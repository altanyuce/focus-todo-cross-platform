import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'package:focus_todo_mobile/sync/real_sync_pipeline.dart';
import 'package:focus_todo_mobile/sync/sync_metadata_helper.dart';
import 'package:focus_todo_mobile/sync/sync_transport_registry.dart';

Task _task({
  int? schemaVersion,
  String id = '11111111-1111-4111-8111-111111111111',
  String title = 'Task',
  String note = '',
  String? dueDate,
  Priority priority = Priority.medium,
  Category category = Category.personal,
  bool completed = false,
  String? completedAt,
  String createdAt = '2026-04-02T09:00:00.000Z',
  String updatedAt = '2026-04-02T09:00:00.000Z',
  String? deletedAt,
  String createdByDeviceId = '11111111-1111-4111-8111-111111111111',
  String updatedByDeviceId = '11111111-1111-4111-8111-111111111111',
}) {
  return Task(
    schemaVersion: schemaVersion ?? currentTaskSchemaVersion,
    id: id,
    title: title,
    note: note,
    dueDate: dueDate,
    priority: priority,
    category: category,
    completed: completed,
    completedAt: completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    createdByDeviceId: createdByDeviceId,
    updatedByDeviceId: updatedByDeviceId,
  );
}

TaskSyncMetadata? _findMetadata(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
) {
  return syncMetadata.cast<TaskSyncMetadata?>().firstWhere(
        (TaskSyncMetadata? item) => item?.taskId == taskId,
        orElse: () => null,
      );
}

void main() {
  group('sync transport selection', () {
    test('fake transport remains the default', () {
      final registry = SyncTransportRegistry();
      expect(registry.getMode(), SyncTransportMode.fake);
    });

    test('supabase transport is available only through explicit internal selection', () {
      final registry = SyncTransportRegistry();
      registry.setMode(SyncTransportMode.supabase);
      expect(registry.getMode(), SyncTransportMode.supabase);
    });

    test('manual/internal sync can run with fake transport mode', () async {
      final registry = SyncTransportRegistry();
      final task = _task();

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: registry.getTransport(),
      );

      expect(result.summary.success, isTrue);
      expect(
        registry.getRemoteSnapshot().any((item) => item.id == task.id),
        isTrue,
      );
    });

    test('missing Supabase config is still safe', () async {
      final registry = SyncTransportRegistry()
        ..setMode(SyncTransportMode.supabase);
      final task = _task();

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: registry.getTransport(),
      );

      final metadata = _findMetadata(result.syncMetadata, task.id);
      expect(result.summary.success, isFalse);
      expect(metadata?.syncStatus, TaskSyncStatus.error);
      expect(metadata?.lastSyncError, 'Supabase sync is not configured');
    });
  });
}
