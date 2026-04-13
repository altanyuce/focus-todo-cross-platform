import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'canonical_task_mapper.dart';
import 'sync_transport.dart';

const String supabaseTodosTable = 'todos';
const String canonicalColumns =
    'id,user_id,title,note,due_date,priority,category,completed,completed_at,created_at,updated_at,deleted_at,created_by_device_id,updated_by_device_id,schema_version';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool _looksLikeUuid(String value) => _uuidPattern.hasMatch(value);

bool _looksLikeIso8601(String? value) {
  if (value == null) {
    return true;
  }
  return DateTime.tryParse(value) != null;
}

void _logSyncPayload(
  String operation,
  CanonicalTask task,
  String? expectedUpdatedAt,
) {
  debugPrint(
    '[SupabaseSync][$operation] taskId=${task.id} payload='
    '${<String, dynamic>{'id': task.id, 'user_id': task.userId, 'title': task.title, 'note': task.note, 'due_date': task.dueDate, 'priority': task.priority, 'category': task.category, 'completed': task.completed, 'completed_at': task.completedAt, 'created_at': task.createdAt, 'updated_at': task.updatedAt, 'deleted_at': task.deletedAt, 'created_by_device_id': task.createdByDeviceId, 'updated_by_device_id': task.updatedByDeviceId, 'schema_version': task.schemaVersion, 'expected_updated_at': expectedUpdatedAt}}',
  );
}

CanonicalTask _canonicalTaskFromBackendRow(Map<String, dynamic> row) {
  return CanonicalTask(
    schemaVersion: row['schema_version'] as int? ?? 1,
    id: row['id'] as String,
    userId: row['user_id'] as String?,
    title: row['title'] as String,
    completed: row['completed'] as bool? ?? false,
    createdAt: row['created_at'] as String,
    updatedAt: row['updated_at'] as String,
    createdByDeviceId: row['created_by_device_id'] as String,
    updatedByDeviceId: row['updated_by_device_id'] as String,
    note: (row['note'] as String?) ?? '',
    dueDate: row['due_date'] as String?,
    priority: row['priority'] as String? ?? 'medium',
    category: row['category'] as String? ?? 'personal',
    completedAt: row['completed_at'] as String?,
    deletedAt: row['deleted_at'] as String?,
  );
}

Map<String, dynamic>? _normalizeRow(dynamic data) {
  if (data is Map) {
    return data.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), value),
    );
  }

  return null;
}

class SupabaseSyncService {
  const SupabaseSyncService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<SyncWriteResult> writeTodo(
    CanonicalTask task,
    String? expectedUpdatedAt,
  ) async {
    if (!_looksLikeUuid(task.id)) {
      debugPrint('[SupabaseSync][write] invalid UUID for taskId=${task.id}');
    }
    if (!_looksLikeIso8601(task.createdAt) ||
        !_looksLikeIso8601(task.updatedAt) ||
        !_looksLikeIso8601(task.completedAt) ||
        !_looksLikeIso8601(task.deletedAt) ||
        !_looksLikeIso8601(expectedUpdatedAt)) {
      debugPrint(
        '[SupabaseSync][write] non-ISO timestamp detected for taskId=${task.id} '
        'created_at=${task.createdAt} updated_at=${task.updatedAt} '
        'completed_at=${task.completedAt} deleted_at=${task.deletedAt} '
        'expected_updated_at=$expectedUpdatedAt',
      );
    }
    _logSyncPayload('write', task, expectedUpdatedAt);

    try {
      final dynamic data = await _client.rpc(
        'upsert_todo_if_version_matches',
        params: <String, dynamic>{
          'p_id': task.id,
          'p_user_id': task.userId,
          'p_title': task.title,
          'p_note': task.note,
          'p_due_date': task.dueDate,
          'p_priority': task.priority,
          'p_category': task.category,
          'p_completed': task.completed,
          'p_completed_at': task.completedAt,
          'p_created_at': task.createdAt,
          'p_updated_at': task.updatedAt,
          'p_deleted_at': task.deletedAt,
          'p_created_by_device_id': task.createdByDeviceId,
          'p_updated_by_device_id': task.updatedByDeviceId,
          'p_schema_version': task.schemaVersion,
          'p_expected_updated_at': expectedUpdatedAt,
        },
      );

      final Map<String, dynamic>? row = data is List && data.isNotEmpty
          ? _normalizeRow(data.first)
          : _normalizeRow(data);
      final CanonicalTask? remoteTask = row == null
          ? null
          : _canonicalTaskFromBackendRow(row);

      debugPrint(
        '[SupabaseSync][write] taskId=${task.id} rpcResult='
        '${<String, dynamic>{'applied': row?['applied'], 'conflict': row?['conflict'], 'remote_id': row?['id'], 'remote_updated_at': row?['updated_at']}}',
      );

      return SyncWriteResult(
        applied: row?['applied'] == true,
        conflict: row?['conflict'] == true,
        remoteTask: remoteTask,
        rowUpdatedAt: remoteTask?.updatedAt,
      );
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseSync][write] failed taskId=${task.id} '
        'message=${error.message} details=${error.details} hint=${error.hint} code=${error.code}',
      );
      throw Exception('Supabase write failed for task ${task.id}: ${error.message}');
    }
  }

  Future<List<CanonicalTask>> pullTodos() async {
    try {
      debugPrint(
        '[SupabaseSync][pull] table=$supabaseTodosTable columns=$canonicalColumns',
      );
      final dynamic data = await _client
          .from(supabaseTodosTable)
          .select(canonicalColumns)
          .order('updated_at', ascending: true)
          .order('id', ascending: true);
      if (data is! List) {
        return const <CanonicalTask>[];
      }

      return data
          .whereType<Map>()
          .map(
            (Map item) => item.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            ),
          )
          .map(_canonicalTaskFromBackendRow)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseSync][pull] failed message=${error.message} '
        'details=${error.details} hint=${error.hint} code=${error.code}',
      );
      throw Exception('Supabase pull failed: ${error.message}');
    }
  }
}
