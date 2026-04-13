import '../shared/models/task.dart';
import '../shared/models/task_sync_metadata.dart';
import 'canonical_task_mapper.dart';
import 'supabase_sync_service.dart';
import 'sync_transport.dart';
import 'supabase_config.dart';

class SupabaseTransportNotConfiguredError implements Exception {
  const SupabaseTransportNotConfiguredError();

  @override
  String toString() => 'Supabase sync is not configured';
}

class SupabaseSyncTransport implements SyncTransport {
  SupabaseSyncTransport({SupabaseConfig? config, SupabaseSyncService? service})
    : _config = config ?? getSupabaseConfig(),
      _service = service ?? const SupabaseSyncService();

  final SupabaseConfig _config;
  final SupabaseSyncService _service;

  bool isConfigured() => hasSupabaseConfig(_config);

  Future<void> _ensureInitialized() async {
    if (!isConfigured()) {
      throw const SupabaseTransportNotConfiguredError();
    }

    await initializeSupabaseIfConfigured(_config);
  }

  @override
  Future<void> pushTasks(List<CanonicalTask> outboundBatch) async {
    await _ensureInitialized();
    throw UnsupportedError('Bulk upsert is no longer used for Supabase sync');
  }

  @override
  Future<SyncWriteResult> writeTask(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    await _ensureInitialized();
    return _service.writeTodo(task, expectedUpdatedAt);
  }

  @override
  Future<List<CanonicalTask>> pullTasks() async {
    await _ensureInitialized();
    return _service.pullTodos();
  }

  @override
  Future<List<CanonicalTask>> syncOnce(
    List<Task> currentTasks,
    List<TaskSyncMetadata> currentSyncMetadata,
  ) async {
    throw UnimplementedError(
      'SupabaseSyncTransport does not support legacy syncOnce; use writeTask + pullTasks',
    );
  }
}
