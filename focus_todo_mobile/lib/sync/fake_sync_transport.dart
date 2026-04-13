import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';
import 'sync_transport.dart';
import 'merge_engine.dart';
import 'mock_sync_flow.dart';

class FakeSyncTransport implements SyncTransport {
  FakeSyncTransport({
    List<CanonicalTask> initialTasks = const <CanonicalTask>[],
  }) {
    for (final CanonicalTask task in initialTasks) {
      _remoteTasks[task.id] = _clone(task);
    }
  }

  final Map<String, CanonicalTask> _remoteTasks = <String, CanonicalTask>{};
  String? _nextPushError;
  String? _nextPullError;

  void failNextPush(String message) {
    _nextPushError = message;
  }

  void failNextPull(String message) {
    _nextPullError = message;
  }

  List<CanonicalTask> snapshot() {
    final tasks = _remoteTasks.values.map(_clone).toList(growable: false)
      ..sort(
        (CanonicalTask left, CanonicalTask right) =>
            left.id.compareTo(right.id),
      );
    return tasks;
  }

  @override
  Future<void> pushTasks(List<CanonicalTask> outboundBatch) async {
    if (_nextPushError != null) {
      final message = _nextPushError!;
      _nextPushError = null;
      throw Exception(message);
    }

    for (final CanonicalTask outboundTask in outboundBatch) {
      final existing = _remoteTasks[outboundTask.id];
      if (existing == null) {
        _remoteTasks[outboundTask.id] = _clone(outboundTask);
        continue;
      }

      final merged = mergeTask(
        fromCanonicalTask(existing),
        fromCanonicalTask(outboundTask),
      );
      _remoteTasks[outboundTask.id] = toCanonicalTask(merged);
    }
  }

  @override
  Future<List<CanonicalTask>> pullTasks() async {
    if (_nextPullError != null) {
      final message = _nextPullError!;
      _nextPullError = null;
      throw Exception(message);
    }

    return snapshot();
  }

  @override
  Future<List<CanonicalTask>> syncOnce(
    List<Task> currentTasks,
    List<TaskSyncMetadata> currentSyncMetadata,
  ) async {
    final coordinatorState = initializeMockSyncState(
      tasks: currentTasks,
      syncMetadata: currentSyncMetadata,
    );
    final outboundBatch = prepareMockOutboundPreview(coordinatorState);

    await pushTasks(outboundBatch);
    return pullTasks();
  }

  CanonicalTask _clone(CanonicalTask task) {
    return CanonicalTask(
      schemaVersion: task.schemaVersion,
      id: task.id,
      userId: task.userId,
      title: task.title,
      completed: task.completed,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      createdByDeviceId: task.createdByDeviceId,
      updatedByDeviceId: task.updatedByDeviceId,
      note: task.note,
      dueDate: task.dueDate,
      priority: task.priority,
      category: task.category,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
    );
  }

  @override
  Future<SyncWriteResult> writeTask(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    throw UnimplementedError(
      'FakeSyncTransport does not support versioned writeTask; use syncOnce in fake flows',
    );
  }
}
