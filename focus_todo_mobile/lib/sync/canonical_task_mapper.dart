import '../shared/models/task.dart';

class CanonicalTask {
  const CanonicalTask({
    required this.schemaVersion,
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByDeviceId,
    required this.updatedByDeviceId,
    required this.note,
    required this.dueDate,
    required this.priority,
    required this.category,
    required this.completedAt,
    required this.deletedAt,
  });

  final int schemaVersion;
  final String id;
  final String? userId;
  final String title;
  final bool completed;
  final String createdAt;
  final String updatedAt;
  final String createdByDeviceId;
  final String updatedByDeviceId;
  final String note;
  final String? dueDate;
  final String? priority;
  final String? category;
  final String? completedAt;
  final String? deletedAt;
}

Priority _priorityFromCanonical(String? value) {
  switch (value) {
    case 'low':
      return Priority.low;
    case 'high':
      return Priority.high;
    case 'medium':
    default:
      return Priority.medium;
  }
}

Category _categoryFromCanonical(String? value) {
  switch (value) {
    case 'work':
      return Category.work;
    case 'study':
      return Category.study;
    case 'personal':
    default:
      return Category.personal;
  }
}

CanonicalTask toCanonicalTask(Task localTask) {
  return CanonicalTask(
    schemaVersion: localTask.schemaVersion,
    id: localTask.id,
    userId: localTask.userId,
    title: localTask.title,
    completed: localTask.completed,
    createdAt: localTask.createdAt,
    updatedAt: localTask.updatedAt,
    createdByDeviceId: localTask.createdByDeviceId,
    updatedByDeviceId: localTask.updatedByDeviceId,
    note: localTask.note,
    dueDate: localTask.dueDate,
    priority: localTask.priority.name,
    category: localTask.category.name,
    completedAt: localTask.completedAt,
    deletedAt: localTask.deletedAt,
  );
}

Task fromCanonicalTask(CanonicalTask canonicalTask) {
  return Task(
    schemaVersion: canonicalTask.schemaVersion > 0
        ? canonicalTask.schemaVersion
        : currentTaskSchemaVersion,
    id: canonicalTask.id,
    userId: canonicalTask.userId,
    title: canonicalTask.title,
    note: canonicalTask.note,
    dueDate: canonicalTask.dueDate,
    priority: _priorityFromCanonical(canonicalTask.priority),
    category: _categoryFromCanonical(canonicalTask.category),
    completed: canonicalTask.completed,
    completedAt: canonicalTask.completedAt,
    createdAt: canonicalTask.createdAt,
    updatedAt: canonicalTask.updatedAt,
    deletedAt: canonicalTask.deletedAt,
    createdByDeviceId: canonicalTask.createdByDeviceId,
    updatedByDeviceId: canonicalTask.updatedByDeviceId,
  );
}
