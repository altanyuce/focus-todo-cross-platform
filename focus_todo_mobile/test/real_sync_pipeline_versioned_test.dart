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

TaskSyncMetadata? _findMetadata(
  List<TaskSyncMetadata> syncMetadata,
  String taskId,
) {
  return syncMetadata.cast<TaskSyncMetadata?>().firstWhere(
        (TaskSyncMetadata? item) => item?.taskId == taskId,
        orElse: () => null,
      );
}

class FakeVersionedTransport implements SyncTransport {
  FakeVersionedTransport({
    this.writeResults = const <String, SyncWriteResult>{},
    this.writeFailures = const <String, String>{},
    this.pullResult = const <CanonicalTask>[],
    this.pullFailure,
  });

  final Map<String, SyncWriteResult> writeResults;
  final Map<String, String> writeFailures;
  final List<CanonicalTask> pullResult;
  final String? pullFailure;

  final List<String> writes = <String>[];

  @override
  Future<SyncWriteResult> writeTask(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    writes.add(task.id);

    final failure = writeFailures[task.id];
    if (failure != null) {
      throw Exception(failure);
    }

    return writeResults[task.id] ??
        const SyncWriteResult(
          applied: false,
          conflict: false,
          remoteTask: null,
          rowUpdatedAt: null,
        );
  }

  @override
  Future<void> pushTasks(List<CanonicalTask> outboundBatch) async {}

  @override
  Future<List<CanonicalTask>> pullTasks() async {
    if (pullFailure != null) {
      throw Exception(pullFailure!);
    }
    return pullResult;
  }

  @override
  Future<List<CanonicalTask>> syncOnce(
    List<Task> currentTasks,
    List<TaskSyncMetadata> currentSyncMetadata,
  ) async {
    throw UnimplementedError('syncOnce should not be used here');
  }
}

void main() {
  group('real sync pipeline versioned write edges', () {
    test('expectedUpdatedAt null still syncs and preserves canonical fields', () async {
      final local = _task(
        note: 'Keep this note',
        dueDate: '2026-04-06',
        priority: Priority.high,
        category: Category.study,
      );
      final remote = _task(
        id: local.id,
        title: local.title,
        note: local.note,
        dueDate: local.dueDate,
        priority: local.priority,
        category: local.category,
        updatedAt: '2026-04-02T10:00:00.000Z',
      );
      final transport = FakeVersionedTransport(
        writeResults: <String, SyncWriteResult>{
          local.id: SyncWriteResult(
            applied: true,
            conflict: false,
            remoteTask: toCanonicalTask(remote),
            rowUpdatedAt: remote.updatedAt,
          ),
        },
        pullResult: <CanonicalTask>[toCanonicalTask(remote)],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[local],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(local.id, TaskSyncStatus.pendingUpsert),
        ],
        transport: transport,
      );

      final task = result.tasks.firstWhere((Task item) => item.id == local.id);
      final metadata = _findMetadata(result.syncMetadata, local.id);

      expect(task.note, 'Keep this note');
      expect(task.dueDate, '2026-04-06');
      expect(task.priority, Priority.high);
      expect(task.category, Category.study);
      expect(task.updatedAt, remote.updatedAt);
      expect(metadata?.syncStatus, TaskSyncStatus.synced);
      expect(metadata?.lastKnownServerUpdatedAt, remote.updatedAt);
    });

    test('invalid lastKnownServerUpdatedAt is corrected to newer remote on conflict', () async {
      final local = _task(
        title: 'Local stale edit',
        updatedAt: '2026-04-02T10:00:00.000Z',
      );
      final remote = _task(
        id: local.id,
        title: 'Remote authoritative',
        updatedAt: '2026-04-02T11:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      );
      final transport = FakeVersionedTransport(
        writeResults: <String, SyncWriteResult>{
          local.id: SyncWriteResult(
            applied: false,
            conflict: true,
            remoteTask: toCanonicalTask(remote),
            rowUpdatedAt: remote.updatedAt,
          ),
        },
        pullResult: <CanonicalTask>[toCanonicalTask(remote)],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[local],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(
            local.id,
            TaskSyncStatus.pendingUpsert,
            lastKnownServerUpdatedAt: 'not-a-timestamp',
          ),
        ],
        transport: transport,
      );

      final task = result.tasks.firstWhere((Task item) => item.id == local.id);
      final metadata = _findMetadata(result.syncMetadata, local.id);

      expect(task.title, 'Remote authoritative');
      expect(task.updatedAt, remote.updatedAt);
      expect(metadata?.syncStatus, TaskSyncStatus.synced);
      expect(metadata?.lastKnownServerUpdatedAt, remote.updatedAt);
    });

    test('inconsistent write result marks error and does not mark synced', () async {
      final local = _task();
      final remote = _task(
        id: local.id,
        title: 'Remote but inconsistent',
        updatedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      );
      final transport = FakeVersionedTransport(
        writeResults: <String, SyncWriteResult>{
          local.id: SyncWriteResult(
            applied: false,
            conflict: false,
            remoteTask: toCanonicalTask(remote),
            rowUpdatedAt: remote.updatedAt,
          ),
        },
        pullResult: const <CanonicalTask>[],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[local],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(local.id, TaskSyncStatus.pendingUpsert),
        ],
        transport: transport,
      );

      final metadata = _findMetadata(result.syncMetadata, local.id);

      expect(result.summary.errorCount, greaterThanOrEqualTo(1));
      expect(metadata?.syncStatus, isNot(TaskSyncStatus.synced));
    });

    test('successful write updates task state to server version', () async {
      final local = _task(
        title: 'Local before server write',
        updatedAt: '2026-04-02T09:00:00.000Z',
      );
      final remote = _task(
        id: local.id,
        title: 'Server normalized',
        updatedAt: '2026-04-02T10:00:00.000Z',
      );
      final transport = FakeVersionedTransport(
        writeResults: <String, SyncWriteResult>{
          local.id: SyncWriteResult(
            applied: true,
            conflict: false,
            remoteTask: toCanonicalTask(remote),
            rowUpdatedAt: remote.updatedAt,
          ),
        },
        pullResult: <CanonicalTask>[toCanonicalTask(remote)],
      );

      final result = await runRealSyncPipeline(
        currentTasks: <Task>[local],
        currentSyncMetadata: <TaskSyncMetadata>[
          _metadata(local.id, TaskSyncStatus.pendingUpsert),
        ],
        transport: transport,
      );

      final task = result.tasks.firstWhere((Task item) => item.id == local.id);

      expect(task.title, 'Server normalized');
      expect(task.updatedAt, remote.updatedAt);
    });
  });
}
