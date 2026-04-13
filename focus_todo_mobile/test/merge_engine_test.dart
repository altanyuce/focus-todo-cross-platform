import 'package:flutter_test/flutter_test.dart';

import 'package:focus_todo_mobile/shared/models/task.dart';
import 'package:focus_todo_mobile/sync/merge_engine.dart';

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

void main() {
  group('merge engine precision edges', () {
    test('1ms newer remote timestamp still wins', () {
      final local = _task(
        title: 'Local',
        updatedAt: '2026-04-02T10:00:00.000Z',
      );
      final remote = _task(
        title: 'Remote',
        updatedAt: '2026-04-02T10:00:00.001Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      );

      final merged = mergeTask(local, remote);

      expect(merged.title, 'Remote');
      expect(merged.updatedAt, '2026-04-02T10:00:00.001Z');
    });
  });
}
