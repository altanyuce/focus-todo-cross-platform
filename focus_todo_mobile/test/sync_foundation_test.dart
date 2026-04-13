import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'package:focus_todo_mobile/sync/canonical_task_mapper.dart';
import 'package:focus_todo_mobile/sync/merge_engine.dart';
import 'package:focus_todo_mobile/sync/mock_sync_flow.dart' as mock_flow;
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

TaskSyncMetadata _metadata(
  String taskId,
  TaskSyncStatus status,
) {
  return TaskSyncMetadata(
    taskId: taskId,
    ownerUserId: null,
    syncStatus: status,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
  );
}

void main() {
  group('sync foundation', () {
    test('create task -> pending-upsert appears in outbound candidates', () {
      final task = _task();
      final coordinatorState = mock_flow.initializeMockSyncState(
        tasks: <Task>[task],
        syncMetadata: markPendingUpsert(const <TaskSyncMetadata>[], task.id),
      );

      final outbound = mock_flow.prepareMockOutboundPreview(coordinatorState);

      expect(outbound, hasLength(1));
      expect(outbound.first.id, task.id);
    });

    test('update task -> pending-upsert remains outbound', () {
      final task = _task(updatedAt: '2026-04-02T10:00:00.000Z');
      final coordinatorState = mock_flow.initializeMockSyncState(
        tasks: <Task>[task],
        syncMetadata: markPendingUpsert(
          <TaskSyncMetadata>[_metadata(task.id, TaskSyncStatus.synced)],
          task.id,
        ),
      );

      final outbound = mock_flow.prepareMockOutboundPreview(coordinatorState);

      expect(outbound, hasLength(1));
      expect(outbound.first.id, task.id);
    });

    test('delete task -> pending-delete appears in outbound candidates', () {
      final task = _task(
        deletedAt: '2026-04-02T11:00:00.000Z',
        updatedAt: '2026-04-02T11:00:00.000Z',
      );
      final coordinatorState = mock_flow.initializeMockSyncState(
        tasks: <Task>[task],
        syncMetadata: markPendingDelete(const <TaskSyncMetadata>[], task.id),
      );

      final outbound = mock_flow.prepareMockOutboundPreview(coordinatorState);

      expect(outbound, hasLength(1));
      expect(outbound.first.deletedAt, isNotNull);
    });

    test('inbound newer record beats older local record', () {
      final localTask = _task(updatedAt: '2026-04-02T09:00:00.000Z');
      final remoteTask = _task(
        title: 'Remote newer',
        updatedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      );

      final merged = mergeTask(localTask, remoteTask);

      expect(merged.title, 'Remote newer');
    });

    test('equal updatedAt + deleted remote beats non-deleted local', () {
      final localTask = _task(updatedAt: '2026-04-02T10:00:00.000Z');
      final remoteTask = _task(
        updatedAt: '2026-04-02T10:00:00.000Z',
        deletedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      );

      final merged = mergeTask(localTask, remoteTask);

      expect(merged.deletedAt, isNotNull);
    });

    test('equal updatedAt + equal delete state -> updatedByDeviceId tie-break works', () {
      final localTask = _task(
        updatedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '11111111-1111-4111-8111-111111111111',
      );
      final remoteTask = _task(
        updatedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '99999999-9999-4999-8999-999999999999',
      );

      final merged = mergeTask(localTask, remoteTask);

      expect(
        merged.updatedByDeviceId,
        remoteTask.updatedByDeviceId,
      );
    });

    test('full equality -> remote wins', () {
      final localTask = _task();
      final remoteTask = _task();

      final mergedCanonical = toCanonicalTask(mergeTask(localTask, remoteTask));
      final remoteCanonical = toCanonicalTask(remoteTask);

      expect(mergedCanonical.id, remoteCanonical.id);
      expect(mergedCanonical.title, remoteCanonical.title);
      expect(mergedCanonical.updatedAt, remoteCanonical.updatedAt);
      expect(mergedCanonical.updatedByDeviceId, remoteCanonical.updatedByDeviceId);
    });

    test('schemaVersion missing in old local data normalizes to 1', () {
      final task = Task.fromJson(<String, dynamic>{
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'title': 'Legacy',
        'note': '',
        'dueDate': null,
        'priority': 'medium',
        'category': 'personal',
        'completed': false,
        'completedAt': null,
        'createdAt': '2026-04-02T09:00:00.000Z',
        'updatedAt': '2026-04-02T09:00:00.000Z',
        'deletedAt': null,
        'createdByDeviceId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'updatedByDeviceId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      });

      expect(task.schemaVersion, currentTaskSchemaVersion);
    });
  });
}
