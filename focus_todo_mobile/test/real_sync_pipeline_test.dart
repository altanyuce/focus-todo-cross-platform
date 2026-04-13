import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'package:focus_todo_mobile/sync/canonical_task_mapper.dart';
import 'package:focus_todo_mobile/sync/fake_sync_transport.dart';
import 'package:focus_todo_mobile/sync/real_sync_pipeline.dart';
import 'package:focus_todo_mobile/sync/sync_metadata_helper.dart';

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

TaskSyncMetadata _metadata(String taskId, TaskSyncStatus status) {
  return TaskSyncMetadata(
    taskId: taskId,
    ownerUserId: null,
    syncStatus: status,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
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
  group('real sync pipeline', () {
    test('pending-upsert task is pushed to remote', () async {
      final task = _task();
      final transport = FakeSyncTransport();

      await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: transport,
      );

      expect(transport.snapshot().any((CanonicalTask item) => item.id == task.id), isTrue);
    });

    test('pending-delete tombstone is pushed to remote', () async {
      final task = _task(
        deletedAt: '2026-04-02T10:00:00.000Z',
        updatedAt: '2026-04-02T10:00:00.000Z',
      );
      final transport = FakeSyncTransport();

      await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingDelete(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: transport,
      );

      final remote = transport.snapshot().firstWhere(
            (CanonicalTask item) => item.id == task.id,
          );
      expect(remote.deletedAt, isNotNull);
    });

    test('pulled remote tasks are merged back locally', () async {
      final remoteTask = toCanonicalTask(
        _task(
          id: '22222222-2222-4222-8222-222222222222',
          title: 'Remote only',
          createdByDeviceId: '22222222-2222-4222-8222-222222222222',
          updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
        ),
      );
      final transport = FakeSyncTransport(
        initialTasks: <CanonicalTask>[remoteTask],
      );

      final result = await runRealSyncPipeline(
        currentTasks: const <Task>[],
        currentSyncMetadata: const <TaskSyncMetadata>[],
        transport: transport,
      );

      expect(result.tasks.any((Task item) => item.id == remoteTask.id), isTrue);
    });

    test('remote newer task updates local task', () async {
      final localTask = _task(title: 'Local', updatedAt: '2026-04-02T09:00:00.000Z');
      final remoteTask = toCanonicalTask(
        _task(
          title: 'Remote newer',
          updatedAt: '2026-04-02T10:00:00.000Z',
          updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
        ),
      );
      final transport = FakeSyncTransport(
        initialTasks: <CanonicalTask>[remoteTask],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[localTask],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(localTask.id, TaskSyncStatus.synced),
        ],
        transport: transport,
      );

      expect(
        result.tasks.firstWhere((Task item) => item.id == localTask.id).title,
        'Remote newer',
      );
    });

    test('remote tombstone beats equal-timestamp local active task', () async {
      final localTask = _task(updatedAt: '2026-04-02T10:00:00.000Z');
      final remoteTask = toCanonicalTask(
        _task(
          updatedAt: '2026-04-02T10:00:00.000Z',
          deletedAt: '2026-04-02T10:00:00.000Z',
          updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
        ),
      );
      final transport = FakeSyncTransport(
        initialTasks: <CanonicalTask>[remoteTask],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[localTask],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(localTask.id, TaskSyncStatus.synced),
        ],
        transport: transport,
      );

      expect(
        result.tasks.firstWhere((Task item) => item.id == localTask.id).deletedAt,
        isNotNull,
      );
    });

    test('successful sync marks relevant metadata as synced', () async {
      final task = _task();
      final transport = FakeSyncTransport();

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: transport,
      );

      final metadata = _findMetadata(result.syncMetadata, task.id);
      expect(metadata?.syncStatus, TaskSyncStatus.synced);
      expect(metadata?.lastSyncedAt, isNotNull);
    });

    test('failed transport marks metadata as error', () async {
      final task = _task();
      final transport = FakeSyncTransport()..failNextPush('push failed');

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: transport,
      );

      final metadata = _findMetadata(result.syncMetadata, task.id);
      expect(metadata?.syncStatus, TaskSyncStatus.error);
      expect(metadata?.lastSyncError, 'push failed');
    });

    test('running sync twice is stable/idempotent enough for v1 prototype expectations', () async {
      final task = _task();
      final transport = FakeSyncTransport();

      final first = await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: markPendingUpsert(
          const <TaskSyncMetadata>[],
          task.id,
        ),
        transport: transport,
      );
      final second = await runRealSyncPipeline(
        currentTasks: first.tasks,
        currentSyncMetadata: first.syncMetadata,
        transport: transport,
      );

      expect(first.summary.success, isTrue);
      expect(second.summary.success, isTrue);
      expect(second.outboundBatch, isEmpty);
    });
  });
}
