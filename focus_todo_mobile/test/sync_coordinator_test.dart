import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/shared/models/task_sync_metadata.dart';
import 'package:focus_todo_mobile/sync/canonical_task_mapper.dart';
import 'package:focus_todo_mobile/sync/real_sync_pipeline.dart';
import 'package:focus_todo_mobile/sync/sync_transport.dart';

Task _task({
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
  TaskSyncStatus status, {
  String? lastKnownServerUpdatedAt,
}) {
  return TaskSyncMetadata(
    taskId: taskId,
    ownerUserId: null,
    syncStatus: status,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: lastKnownServerUpdatedAt,
    lastSyncError: null,
  );
}

class _RecordingVersionedTransport implements SyncTransport {
  _RecordingVersionedTransport({
    required this.writeResult,
    this.pullResult = const <CanonicalTask>[],
  });

  final SyncWriteResult writeResult;
  final List<CanonicalTask> pullResult;
  final List<String?> expectedUpdatedAtValues = <String?>[];

  @override
  Future<SyncWriteResult> writeTask(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    expectedUpdatedAtValues.add(expectedUpdatedAt);
    return writeResult;
  }

  @override
  Future<void> pushTasks(List<CanonicalTask> outboundBatch) async {}

  @override
  Future<List<CanonicalTask>> pullTasks() async => pullResult;

  @override
  Future<List<CanonicalTask>> syncOnce(
    List<Task> currentTasks,
    List<TaskSyncMetadata> currentSyncMetadata,
  ) async {
    throw UnimplementedError('syncOnce should not be used here');
  }
}

void main() {
  group('versioned write edge cases', () {
    test('lastKnownServerUpdatedAt is passed to versioned writes', () async {
      final task = _task(
        note: 'Keep this',
        dueDate: '2026-04-05',
        priority: Priority.high,
        category: Category.work,
      );
      final transport = _RecordingVersionedTransport(
        writeResult: SyncWriteResult(
          applied: true,
          conflict: false,
          remoteTask: toCanonicalTask(task),
          rowUpdatedAt: task.updatedAt,
        ),
        pullResult: <CanonicalTask>[toCanonicalTask(task)],
      );
      const expectedUpdatedAt = '2026-04-02T10:30:00.000Z';

      await runRealSyncPipeline(
        currentTasks: <Task>[task],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(
            task.id,
            TaskSyncStatus.pendingUpsert,
            lastKnownServerUpdatedAt: expectedUpdatedAt,
          ),
        ],
        transport: transport,
      );

      expect(transport.expectedUpdatedAtValues, <String?>[expectedUpdatedAt]);
    });

    test(
      'successful versioned write uses server updatedAt, not local',
      () async {
        final task = _task(
          title: 'Local',
          updatedAt: '2026-04-02T09:00:00.000Z',
        );
        final remote = _task(
          id: task.id,
          title: 'Server canonical',
          updatedAt: '2026-04-02T10:00:00.000Z',
        );
        final transport = _RecordingVersionedTransport(
          writeResult: SyncWriteResult(
            applied: true,
            conflict: false,
            remoteTask: toCanonicalTask(remote),
            rowUpdatedAt: remote.updatedAt,
          ),
          pullResult: <CanonicalTask>[toCanonicalTask(remote)],
        );

        final nextState = await runRealSyncPipeline(
          currentTasks: <Task>[task],
          currentSyncMetadata: <TaskSyncMetadata>[
            _metadata(task.id, TaskSyncStatus.pendingUpsert),
          ],
          transport: transport,
        );

        final syncedTask = nextState.tasks.firstWhere(
          (Task item) => item.id == task.id,
        );
        final metadata = nextState.syncMetadata.firstWhere(
          (TaskSyncMetadata item) => item.taskId == task.id,
        );

        expect(syncedTask.updatedAt, remote.updatedAt);
        expect(syncedTask.updatedAt, isNot(task.updatedAt));
        expect(metadata.lastKnownServerUpdatedAt, remote.updatedAt);
      },
    );
  });
}
