import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';
import 'merge_engine.dart';
import 'sync_coordinator.dart';
import 'sync_metadata_helper.dart';
import 'sync_transport.dart';

class RealSyncPipelineSummary {
  const RealSyncPipelineSummary({
    required this.pushedCount,
    required this.pulledCount,
    required this.syncedCount,
    required this.errorCount,
    required this.success,
    required this.errorMessage,
  });

  final int pushedCount;
  final int pulledCount;
  final int syncedCount;
  final int errorCount;
  final bool success;
  final String? errorMessage;
}

class RealSyncPipelineResult {
  const RealSyncPipelineResult({
    required this.tasks,
    required this.syncMetadata,
    required this.coordinatorState,
    required this.outboundBatch,
    required this.pulledRemoteTasks,
    required this.summary,
  });

  final List<Task> tasks;
  final List<TaskSyncMetadata> syncMetadata;
  final SyncCoordinatorState coordinatorState;
  final List<CanonicalTask> outboundBatch;
  final List<CanonicalTask> pulledRemoteTasks;
  final RealSyncPipelineSummary summary;
}

List<TaskSyncMetadata> _markRemoteTasksSynced(
  List<TaskSyncMetadata> syncMetadata,
  List<CanonicalTask> remoteTasks,
  String lastSyncedAt,
) {
  return remoteTasks.fold<List<TaskSyncMetadata>>(syncMetadata, (
    List<TaskSyncMetadata> current,
    CanonicalTask remoteTask,
  ) {
    final existing = current.cast<TaskSyncMetadata?>().firstWhere(
      (TaskSyncMetadata? item) => item?.taskId == remoteTask.id,
      orElse: () => null,
    );
    if (existing?.syncStatus != TaskSyncStatus.synced) {
      return current;
    }

    return markSynced(
      current,
      remoteTask.id,
      options: MarkSyncedOptions(
        lastKnownServerUpdatedAt: remoteTask.updatedAt,
        lastSyncedAt: lastSyncedAt,
      ),
    );
  });
}

List<TaskSyncMetadata> _markOutboundTasksError(
  List<TaskSyncMetadata> syncMetadata,
  List<CanonicalTask> outboundBatch,
  String errorMessage,
) {
  return outboundBatch.fold<List<TaskSyncMetadata>>(
    syncMetadata,
    (List<TaskSyncMetadata> current, CanonicalTask task) =>
        markError(current, task.id, errorMessage),
  );
}

Future<RealSyncPipelineResult> runRealSyncPipeline({
  required List<Task> currentTasks,
  required List<TaskSyncMetadata> currentSyncMetadata,
  required SyncTransport transport,
}) async {
  final coordinatorState = syncCoordinator.initializeAfterHydration(
    tasks: currentTasks,
    syncMetadata: currentSyncMetadata,
  );
  final outboundBatch = syncCoordinator.prepareOutboundBatch(coordinatorState);
  var nextTasks = List<Task>.from(coordinatorState.tasks, growable: true);
  var nextSyncMetadata = List<TaskSyncMetadata>.from(
    coordinatorState.syncMetadata,
    growable: true,
  );
  var errorCount = 0;

  for (final CanonicalTask outboundTask in outboundBatch) {
    final metadata = nextSyncMetadata.cast<TaskSyncMetadata?>().firstWhere(
      (TaskSyncMetadata? item) => item?.taskId == outboundTask.id,
      orElse: () => null,
    );

    try {
      final result = await transport.writeTask(
        outboundTask,
        metadata?.lastKnownServerUpdatedAt,
      );

      if (result.remoteTask == null) {
        errorCount += 1;
        nextSyncMetadata = markError(
          nextSyncMetadata,
          outboundTask.id,
          'Missing canonical row in sync write result',
        );
        continue;
      }

      final remoteTask = fromCanonicalTask(result.remoteTask!);
      final localIndex = nextTasks.indexWhere(
        (Task task) => task.id == remoteTask.id,
      );

      if (localIndex == -1 || result.applied) {
        if (localIndex == -1) {
          nextTasks.add(remoteTask);
        } else {
          nextTasks[localIndex] = remoteTask;
        }
        nextSyncMetadata = markSynced(
          nextSyncMetadata,
          remoteTask.id,
          options: MarkSyncedOptions(
            lastKnownServerUpdatedAt:
                result.rowUpdatedAt ?? remoteTask.updatedAt,
            lastSyncedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
        continue;
      }

      final localTask = nextTasks[localIndex];
      final mergedTask = mergeTask(localTask, remoteTask);
      nextTasks[localIndex] = mergedTask;
      nextSyncMetadata =
          mergedTask.updatedAt == remoteTask.updatedAt &&
              mergedTask.updatedByDeviceId == remoteTask.updatedByDeviceId
          ? markSynced(
              nextSyncMetadata,
              remoteTask.id,
              options: MarkSyncedOptions(
                lastKnownServerUpdatedAt:
                    result.rowUpdatedAt ?? remoteTask.updatedAt,
                lastSyncedAt: DateTime.now().toUtc().toIso8601String(),
              ),
            )
          : mergedTask.deletedAt != null
          ? markPendingDelete(nextSyncMetadata, mergedTask.id)
          : markPendingUpsert(nextSyncMetadata, mergedTask.id);
    } catch (error) {
      errorCount += 1;
      nextSyncMetadata = markError(
        nextSyncMetadata,
        outboundTask.id,
        error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Sync transport failed',
      );
    }
  }

  try {
    final pulledRemoteTasks = await transport.pullTasks();
    final inboundAppliedState = syncCoordinator.applyInboundBatch(
      SyncCoordinatorState(
        initializedAfterHydration: coordinatorState.initializedAfterHydration,
        tasks: List<Task>.unmodifiable(nextTasks),
        syncMetadata: List<TaskSyncMetadata>.unmodifiable(nextSyncMetadata),
      ),
      pulledRemoteTasks,
    );
    final lastSyncedAt = DateTime.now().toUtc().toIso8601String();
    final finalSyncMetadata = _markRemoteTasksSynced(
      inboundAppliedState.syncMetadata,
      pulledRemoteTasks,
      lastSyncedAt,
    );

    return RealSyncPipelineResult(
      tasks: inboundAppliedState.tasks,
      syncMetadata: finalSyncMetadata,
      coordinatorState: SyncCoordinatorState(
        initializedAfterHydration:
            inboundAppliedState.initializedAfterHydration,
        tasks: inboundAppliedState.tasks,
        syncMetadata: finalSyncMetadata,
      ),
      outboundBatch: outboundBatch,
      pulledRemoteTasks: pulledRemoteTasks,
      summary: RealSyncPipelineSummary(
        pushedCount: outboundBatch.length - errorCount,
        pulledCount: pulledRemoteTasks.length,
        syncedCount: pulledRemoteTasks.length,
        errorCount: errorCount,
        success: errorCount == 0,
        errorMessage: errorCount == 0 ? null : 'One or more sync writes failed',
      ),
    );
  } catch (error) {
    final errorMessage = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : 'Sync transport failed';
    final errorSyncMetadata = _markOutboundTasksError(
      nextSyncMetadata,
      outboundBatch,
      errorMessage,
    );

    return RealSyncPipelineResult(
      tasks: List<Task>.unmodifiable(nextTasks),
      syncMetadata: errorSyncMetadata,
      coordinatorState: SyncCoordinatorState(
        initializedAfterHydration: coordinatorState.initializedAfterHydration,
        tasks: List<Task>.unmodifiable(nextTasks),
        syncMetadata: errorSyncMetadata,
      ),
      outboundBatch: outboundBatch,
      pulledRemoteTasks: const <CanonicalTask>[],
      summary: RealSyncPipelineSummary(
        pushedCount: outboundBatch.length,
        pulledCount: 0,
        syncedCount: 0,
        errorCount: outboundBatch.length,
        success: false,
        errorMessage: errorMessage,
      ),
    );
  }
}
