import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';

class SyncWriteResult {
  const SyncWriteResult({
    required this.applied,
    required this.conflict,
    required this.remoteTask,
    required this.rowUpdatedAt,
  });

  final bool applied;
  final bool conflict;
  final CanonicalTask? remoteTask;
  final String? rowUpdatedAt;
}

abstract class SyncTransport {
  Future<SyncWriteResult> writeTask(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    throw UnimplementedError('Versioned write is not supported');
  }

  Future<void> pushTasks(List<CanonicalTask> outboundBatch) async {
    throw UnimplementedError('Bulk push is not supported');
  }

  Future<List<CanonicalTask>> pullTasks();

  Future<List<CanonicalTask>> syncOnce(
    List<Task> currentTasks,
    List<TaskSyncMetadata> currentSyncMetadata,
  ) async {
    throw UnimplementedError('One-shot sync is not supported');
  }
}
