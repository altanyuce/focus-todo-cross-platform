import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';
import 'sync_coordinator.dart';

class MockSyncCycleResult {
  const MockSyncCycleResult({
    required this.outboundBatch,
    required this.coordinatorState,
  });

  final List<CanonicalTask> outboundBatch;
  final SyncCoordinatorState coordinatorState;
}

const MockSyncCoordinator _mockSyncCoordinator = MockSyncCoordinator();

SyncCoordinatorState initializeMockSyncState({
  required List<Task> tasks,
  required List<TaskSyncMetadata> syncMetadata,
}) {
  return _mockSyncCoordinator.initializeAfterHydration(
    tasks: tasks,
    syncMetadata: syncMetadata,
  );
}

List<CanonicalTask> prepareMockOutboundPreview(
  SyncCoordinatorState coordinatorState,
) {
  return _mockSyncCoordinator.prepareOutboundBatch(coordinatorState);
}

SyncCoordinatorState applyMockInboundTasks(
  SyncCoordinatorState coordinatorState,
  List<CanonicalTask> mockData,
) {
  return _mockSyncCoordinator.applyInboundBatch(coordinatorState, mockData);
}

MockSyncCycleResult runMockSyncCycle(
  SyncCoordinatorState coordinatorState, {
  List<CanonicalTask> mockData = const <CanonicalTask>[],
}) {
  final outboundBatch = prepareMockOutboundPreview(coordinatorState);
  final nextCoordinatorState = applyMockInboundTasks(
    coordinatorState,
    mockData,
  );

  return MockSyncCycleResult(
    outboundBatch: outboundBatch,
    coordinatorState: nextCoordinatorState,
  );
}
