import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';
import 'merge_engine.dart';
import 'outbound_selector.dart';
import 'sync_metadata_helper.dart';

class SyncCoordinatorState {
  const SyncCoordinatorState({
    required this.initializedAfterHydration,
    required this.tasks,
    required this.syncMetadata,
  });

  final bool initializedAfterHydration;
  final List<Task> tasks;
  final List<TaskSyncMetadata> syncMetadata;
}

abstract class SyncCoordinator {
  SyncCoordinatorState initializeAfterHydration({
    required List<Task> tasks,
    required List<TaskSyncMetadata> syncMetadata,
  });

  List<CanonicalTask> prepareOutboundBatch(SyncCoordinatorState state);

  SyncCoordinatorState applyInboundBatch(
    SyncCoordinatorState state,
    List<CanonicalTask> mockData,
  );
}

class TaskSyncCoordinator extends MockSyncCoordinator {
  const TaskSyncCoordinator();
}

const SyncCoordinator syncCoordinator = TaskSyncCoordinator();

bool _sameWinner(Task left, Task right) {
  return left.schemaVersion == right.schemaVersion &&
      left.id == right.id &&
      left.title == right.title &&
      left.note == right.note &&
      left.dueDate == right.dueDate &&
      left.priority == right.priority &&
      left.category == right.category &&
      left.completed == right.completed &&
      left.completedAt == right.completedAt &&
      left.createdAt == right.createdAt &&
      left.updatedAt == right.updatedAt &&
      left.deletedAt == right.deletedAt &&
      left.createdByDeviceId == right.createdByDeviceId &&
      left.updatedByDeviceId == right.updatedByDeviceId;
}

class MockSyncCoordinator implements SyncCoordinator {
  const MockSyncCoordinator();

  @override
  SyncCoordinatorState initializeAfterHydration({
    required List<Task> tasks,
    required List<TaskSyncMetadata> syncMetadata,
  }) {
    return SyncCoordinatorState(
      initializedAfterHydration: true,
      tasks: List<Task>.from(tasks, growable: false),
      syncMetadata: List<TaskSyncMetadata>.from(syncMetadata, growable: false),
    );
  }

  @override
  List<CanonicalTask> prepareOutboundBatch(SyncCoordinatorState state) {
    if (!state.initializedAfterHydration) {
      return const <CanonicalTask>[];
    }

    return getOutboundTasks(
      state.tasks,
      state.syncMetadata,
    ).map(toCanonicalTask).toList(growable: false);
  }

  @override
  SyncCoordinatorState applyInboundBatch(
    SyncCoordinatorState state,
    List<CanonicalTask> mockData,
  ) {
    if (!state.initializedAfterHydration || mockData.isEmpty) {
      return SyncCoordinatorState(
        initializedAfterHydration: state.initializedAfterHydration,
        tasks: List<Task>.from(state.tasks, growable: false),
        syncMetadata: List<TaskSyncMetadata>.from(
          state.syncMetadata,
          growable: false,
        ),
      );
    }

    var tasks = List<Task>.from(state.tasks, growable: true);
    var syncMetadata = List<TaskSyncMetadata>.from(
      state.syncMetadata,
      growable: false,
    );

    for (final CanonicalTask item in mockData) {
      final remoteTask = fromCanonicalTask(item);
      final localIndex = tasks.indexWhere(
        (Task task) => task.id == remoteTask.id,
      );

      if (localIndex == -1) {
        tasks.add(remoteTask);
        syncMetadata = markSynced(
          syncMetadata,
          remoteTask.id,
          options: MarkSyncedOptions(
            lastKnownServerUpdatedAt: remoteTask.updatedAt,
          ),
        );
        continue;
      }

      final localTask = tasks[localIndex];
      final mergedTask = mergeTask(localTask, remoteTask);
      tasks[localIndex] = mergedTask;

      syncMetadata = _sameWinner(mergedTask, remoteTask)
          ? markSynced(
              syncMetadata,
              remoteTask.id,
              options: MarkSyncedOptions(
                lastKnownServerUpdatedAt: remoteTask.updatedAt,
              ),
            )
          : mergedTask.deletedAt != null
          ? markPendingDelete(syncMetadata, mergedTask.id)
          : markPendingUpsert(syncMetadata, mergedTask.id);
    }

    return SyncCoordinatorState(
      initializedAfterHydration: state.initializedAfterHydration,
      tasks: List<Task>.unmodifiable(tasks),
      syncMetadata: List<TaskSyncMetadata>.unmodifiable(syncMetadata),
    );
  }
}
