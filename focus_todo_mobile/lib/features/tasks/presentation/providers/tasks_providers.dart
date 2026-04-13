import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/device_identity_local_data_source.dart';
import '../../../../shared/models/task.dart';
import '../../../../shared/models/task_sync_metadata.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../../sync/canonical_task_mapper.dart';
import '../../../../sync/mock_sync_flow.dart' as mock_sync_flow;
import '../../../../sync/real_sync_pipeline.dart';
import '../../../../sync/supabase_sync_transport.dart';
import '../../../../sync/sync_coordinator.dart';
import '../../../../sync/sync_transport_registry.dart';
import '../../data/local/task_local_data_source.dart';
import '../../data/local/tasks_ui_local_data_source.dart';
import '../../data/models/task_data_state.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/queries/task_queries.dart';
import '../../domain/repositories/task_repository.dart';
import '../state/tasks_state.dart';
import '../state/tasks_ui_state.dart';

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((Ref ref) {
  return TaskLocalDataSource();
});

final tasksUiLocalDataSourceProvider = Provider<TasksUiLocalDataSource>((
  Ref ref,
) {
  return TasksUiLocalDataSource();
});

final deviceIdentityLocalDataSourceProvider =
    Provider<DeviceIdentityLocalDataSource>((Ref ref) {
      return DeviceIdentityLocalDataSource();
    });

final taskRepositoryProvider = Provider<TaskRepository>((Ref ref) {
  return TaskRepositoryImpl(ref.read(taskLocalDataSourceProvider));
});

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);

final visibleTasksProvider = Provider<List<Task>>((Ref ref) {
  final state = ref.watch(tasksProvider);
  final ui = state.ui;

  return visibleTasks(
    state.tasks,
    section: ui.section,
    search: ui.search,
    statusFilter: ui.statusFilter,
    priorityFilter: ui.priorityFilter,
    categoryFilter: ui.categoryFilter,
  );
});

final sortedVisibleTasksProvider = Provider<List<Task>>((Ref ref) {
  final state = ref.watch(tasksProvider);

  return sortTasksForDisplay(
    ref.watch(visibleTasksProvider),
    section: state.ui.section,
    sortOrder: state.ui.sortOrder,
  );
});

final sortedVisibleTasksForSectionProvider =
    Provider.family<List<Task>, Section>((Ref ref, Section section) {
      final state = ref.watch(tasksProvider);
      final ui = state.ui;

      final list = visibleTasks(
        state.tasks,
        section: section,
        search: ui.search,
        statusFilter: ui.statusFilter,
        priorityFilter: ui.priorityFilter,
        categoryFilter: ui.categoryFilter,
      );

      return sortTasksForDisplay(
        list,
        section: section,
        sortOrder: ui.sortOrder,
      );
    });

class TasksNotifier extends Notifier<TasksState> {
  bool _initialized = false;
  SyncCoordinatorState? _syncCoordinatorState;
  final SyncTransportRegistry _realSyncTransportRegistry =
      SyncTransportRegistry()..setMode(SyncTransportMode.supabase);

  @override
  TasksState build() {
    return const TasksState(
      deviceId: '',
      tasks: <Task>[],
      syncMetadata: <TaskSyncMetadata>[],
      ui: TasksUiState.initial,
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final deviceId = await ref
        .read(deviceIdentityLocalDataSourceProvider)
        .getOrCreateDeviceId();
    final repository = ref.read(taskRepositoryProvider);
    final uiLocalDataSource = ref.read(tasksUiLocalDataSourceProvider);
    final taskData = await repository.loadState();
    final uiState = await uiLocalDataSource.loadState();

    state = _buildHydratedState(
      deviceId: deviceId,
      taskData: taskData,
      uiState: uiState,
    );
    _refreshSyncCoordinatorState();

    _initialized = true;

    if (taskData == null) {
      await _persistTaskDataNow();
    }

    if (uiState == null) {
      await _persistUiStateNow();
    }
  }

  TasksState _buildHydratedState({
    required String deviceId,
    required TaskDataState? taskData,
    required TasksUiState? uiState,
  }) {
    final tasks = (taskData?.tasks ?? const <Task>[])
        .map((Task task) => _normalizeTask(task, deviceId))
        .whereType<Task>()
        .toList(growable: false);

    final syncMetadataByTaskId = <String, TaskSyncMetadata>{
      for (final TaskSyncMetadata item
          in taskData?.syncMetadata ?? const <TaskSyncMetadata>[])
        if (_isUuid(item.taskId))
          item.taskId: _normalizeSyncMetadata(item, item.taskId),
    };

    return TasksState(
      deviceId: deviceId,
      tasks: tasks,
      syncMetadata: tasks
          .map(
            (Task task) =>
                syncMetadataByTaskId[task.id] ??
                _defaultSyncMetadata(
                  task.id,
                  task.deletedAt != null
                      ? TaskSyncStatus.pendingDelete
                      : TaskSyncStatus.pendingUpsert,
                ),
          )
          .toList(growable: false),
      ui: uiState ?? TasksUiState.initial,
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  bool _isIsoTimestamp(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    return DateTime.tryParse(value)?.toUtc().toIso8601String().isNotEmpty ??
        false;
  }

  String? _normalizeLocalDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ? value : null;
  }

  String _normalizeDeviceId(String value, String fallback) {
    return _isUuid(value) ? value : fallback;
  }

  Task? _normalizeTask(Task task, String deviceId) {
    final id = task.id.trim();
    final title = task.title.trim();

    if (!_isUuid(id) || title.isEmpty || !_isIsoTimestamp(task.createdAt)) {
      return null;
    }

    final updatedAt = _isIsoTimestamp(task.updatedAt)
        ? task.updatedAt
        : task.createdAt;
    final completedAt = _isIsoTimestamp(task.completedAt)
        ? task.completedAt
        : null;
    final completed = task.completed && completedAt != null;
    final deletedAt = _isIsoTimestamp(task.deletedAt) ? task.deletedAt : null;
    final dueDate = _normalizeLocalDate(task.dueDate);

    return task.copyWith(
      schemaVersion: task.schemaVersion > 0
          ? task.schemaVersion
          : currentTaskSchemaVersion,
      id: id,
      title: title,
      note: task.note,
      dueDate: dueDate,
      clearDueDate: dueDate == null,
      completed: completed,
      completedAt: completed ? completedAt : null,
      clearCompletedAt: !completed,
      createdAt: task.createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      clearDeletedAt: deletedAt == null,
      createdByDeviceId: _normalizeDeviceId(task.createdByDeviceId, deviceId),
      updatedByDeviceId: _normalizeDeviceId(task.updatedByDeviceId, deviceId),
    );
  }

  TaskSyncMetadata _normalizeSyncMetadata(
    TaskSyncMetadata metadata,
    String taskId,
  ) {
    return TaskSyncMetadata(
      taskId: taskId,
      ownerUserId: metadata.ownerUserId,
      syncStatus: metadata.syncStatus,
      lastSyncedAt: _isIsoTimestamp(metadata.lastSyncedAt)
          ? metadata.lastSyncedAt
          : null,
      lastKnownServerUpdatedAt:
          _isIsoTimestamp(metadata.lastKnownServerUpdatedAt)
          ? metadata.lastKnownServerUpdatedAt
          : null,
      lastSyncError: metadata.lastSyncError,
    );
  }

  TaskSyncMetadata _defaultSyncMetadata(
    String taskId,
    TaskSyncStatus syncStatus,
  ) {
    return TaskSyncMetadata(
      taskId: taskId,
      ownerUserId: null,
      syncStatus: syncStatus,
      lastSyncedAt: null,
      lastKnownServerUpdatedAt: null,
      lastSyncError: null,
    );
  }

  List<TaskSyncMetadata> _upsertSyncMetadata(
    List<TaskSyncMetadata> syncMetadata,
    String taskId,
    TaskSyncStatus syncStatus,
  ) {
    final existing = syncMetadata.cast<TaskSyncMetadata?>().firstWhere(
      (TaskSyncMetadata? item) => item?.taskId == taskId,
      orElse: () => null,
    );

    final next = existing != null
        ? existing.copyWith(
            syncStatus: syncStatus,
            clearLastSyncError: true,
          )
        : _defaultSyncMetadata(taskId, syncStatus);

    return <TaskSyncMetadata>[
      next,
      ...syncMetadata.where((TaskSyncMetadata item) => item.taskId != taskId),
    ];
  }

  void hydrate(TasksState nextState) {
    state = nextState;
    _refreshSyncCoordinatorState();
    _persistTaskData();
    _persistUiState();
  }

  void addTask({
    required String title,
    required String note,
    required String? dueDate,
    required Priority priority,
    required Category category,
  }) {
    if (title.trim().isEmpty) {
      return;
    }

    final timestamp = _nowIso();
    final task = Task(
      schemaVersion: currentTaskSchemaVersion,
      id: UuidGenerator.generate(),
      userId: '11111111-1111-1111-1111-111111111111',
      title: title.trim(),
      note: note.trim(),
      dueDate: dueDate,
      priority: priority,
      category: category,
      completed: false,
      completedAt: null,
      createdAt: timestamp,
      updatedAt: timestamp,
      deletedAt: null,
      createdByDeviceId: state.deviceId,
      updatedByDeviceId: state.deviceId,
    );

    state = state.copyWith(
      tasks: <Task>[task, ...state.tasks],
      syncMetadata: _upsertSyncMetadata(
        state.syncMetadata,
        task.id,
        TaskSyncStatus.pendingUpsert,
      ),
    );
    _refreshSyncCoordinatorState();
    _persistTaskData();
  }

  void updateTask(
    String id, {
    String? title,
    String? note,
    String? dueDate,
    bool clearDueDate = false,
    Priority? priority,
    Category? category,
    bool? completed,
    String? completedAt,
    bool clearCompletedAt = false,
  }) {
    state = state.copyWith(
      tasks: state.tasks
          .map((Task task) {
            if (task.id != id) {
              return task;
            }

            return task.copyWith(
              title: title,
              note: note,
              dueDate: dueDate,
              clearDueDate: clearDueDate,
              priority: priority,
              category: category,
              completed: completed,
              completedAt: completedAt,
              clearCompletedAt: clearCompletedAt,
              updatedAt: _nowIso(),
              updatedByDeviceId: state.deviceId,
            );
          })
          .toList(growable: false),
      syncMetadata: _upsertSyncMetadata(
        state.syncMetadata,
        id,
        TaskSyncStatus.pendingUpsert,
      ),
    );
    _refreshSyncCoordinatorState();
    _persistTaskData();
  }

  void deleteTask(String id) {
    final deletedAt = _nowIso();

    state = state.copyWith(
      tasks: state.tasks
          .map((Task task) {
            if (task.id != id) {
              return task;
            }

            return task.copyWith(
              deletedAt: deletedAt,
              updatedAt: deletedAt,
              updatedByDeviceId: state.deviceId,
            );
          })
          .toList(growable: false),
      syncMetadata: _upsertSyncMetadata(
        state.syncMetadata,
        id,
        TaskSyncStatus.pendingDelete,
      ),
    );
    _refreshSyncCoordinatorState();
    _persistTaskData();
  }

  void toggleComplete(String id) {
    final timestamp = _nowIso();

    state = state.copyWith(
      tasks: state.tasks
          .map((Task task) {
            if (task.id != id) {
              return task;
            }

            final completed = !task.completed;
            return task.copyWith(
              completed: completed,
              completedAt: completed ? timestamp : null,
              clearCompletedAt: !completed,
              updatedAt: timestamp,
              updatedByDeviceId: state.deviceId,
            );
          })
          .toList(growable: false),
      syncMetadata: _upsertSyncMetadata(
        state.syncMetadata,
        id,
        TaskSyncStatus.pendingUpsert,
      ),
    );
    _refreshSyncCoordinatorState();
    _persistTaskData();
  }

  void setUi({
    Section? section,
    String? search,
    StatusFilter? statusFilter,
    PriorityFilter? priorityFilter,
    CategoryFilter? categoryFilter,
    SortOrder? sortOrder,
  }) {
    state = state.copyWith(
      ui: state.ui.copyWith(
        section: section,
        search: search,
        statusFilter: statusFilter,
        priorityFilter: priorityFilter,
        categoryFilter: categoryFilter,
        sortOrder: sortOrder,
      ),
    );
    _persistUiState();
  }

  void setSection(Section section) {
    setUi(section: section);
  }

  SyncCoordinatorState? getMockSyncCoordinatorState() {
    return _syncCoordinatorState;
  }

  List<CanonicalTask> prepareMockOutboundPreview() {
    final coordinatorState = _ensureSyncCoordinatorState();
    return mock_sync_flow.prepareMockOutboundPreview(coordinatorState);
  }

  void applyMockInboundTasks(List<CanonicalTask> mockData) {
    final coordinatorState = _ensureSyncCoordinatorState();
    final nextCoordinatorState = mock_sync_flow.applyMockInboundTasks(
      coordinatorState,
      mockData,
    );
    _applyCoordinatorState(nextCoordinatorState);
  }

  List<CanonicalTask> runMockSyncCycle({
    List<CanonicalTask> mockInbound = const <CanonicalTask>[],
  }) {
    final coordinatorState = _ensureSyncCoordinatorState();
    final result = mock_sync_flow.runMockSyncCycle(
      coordinatorState,
      mockData: mockInbound,
    );
    _applyCoordinatorState(result.coordinatorState);
    return result.outboundBatch;
  }

  bool isManualSyncConfigured() {
    final transport = _realSyncTransportRegistry.getTransport();
    return transport is! SupabaseSyncTransport || transport.isConfigured();
  }

  Future<RealSyncPipelineResult> runManualSync() async {
    final result = await runRealSyncPipeline(
      currentTasks: state.tasks,
      currentSyncMetadata: state.syncMetadata,
      transport: _realSyncTransportRegistry.getTransport(),
    );
    _applyCoordinatorState(result.coordinatorState);
    return result;
  }

  Future<RealSyncPipelineResult> runRealSyncPrototypeOnce() {
    return runManualSync();
  }

  List<CanonicalTask> getRealSyncRemoteSnapshot() {
    return _realSyncTransportRegistry.getRemoteSnapshot();
  }

  SyncTransportMode getRealSyncTransportMode() {
    return _realSyncTransportRegistry.getMode();
  }

  void setRealSyncTransportMode(SyncTransportMode mode) {
    _realSyncTransportRegistry.setMode(mode);
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  void _refreshSyncCoordinatorState() {
    _syncCoordinatorState = mock_sync_flow.initializeMockSyncState(
      tasks: state.tasks,
      syncMetadata: state.syncMetadata,
    );
  }

  SyncCoordinatorState _ensureSyncCoordinatorState() {
    return _syncCoordinatorState ??
        mock_sync_flow.initializeMockSyncState(
          tasks: state.tasks,
          syncMetadata: state.syncMetadata,
        );
  }

  void _applyCoordinatorState(SyncCoordinatorState nextCoordinatorState) {
    _syncCoordinatorState = nextCoordinatorState;
    state = state.copyWith(
      tasks: nextCoordinatorState.tasks,
      syncMetadata: nextCoordinatorState.syncMetadata,
    );
    _persistTaskData();
  }

  Future<void> _persistTaskDataNow() async {
    if (!_initialized) {
      return;
    }

    await ref
        .read(taskRepositoryProvider)
        .saveState(
          TaskDataState(tasks: state.tasks, syncMetadata: state.syncMetadata),
        );
  }

  Future<void> _persistUiStateNow() async {
    if (!_initialized) {
      return;
    }

    await ref.read(tasksUiLocalDataSourceProvider).saveState(state.ui);
  }

  void _persistTaskData() {
    unawaited(_persistTaskDataNow());
  }

  void _persistUiState() {
    unawaited(_persistUiStateNow());
  }
}
