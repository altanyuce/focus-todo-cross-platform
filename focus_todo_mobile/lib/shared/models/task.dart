enum Priority { low, medium, high }

enum Category { personal, work, study }

const int currentTaskSchemaVersion = 1;

class Task {
  const Task({
    this.schemaVersion = currentTaskSchemaVersion,
    required this.id,
    this.userId,
    required this.title,
    required this.note,
    required this.dueDate,
    required this.priority,
    required this.category,
    required this.completed,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.createdByDeviceId,
    required this.updatedByDeviceId,
  });

  final int schemaVersion;
  final String id;
  final String? userId;
  final String title;
  final String note;
  final String? dueDate;
  final Priority priority;
  final Category category;
  final bool completed;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String createdByDeviceId;
  final String updatedByDeviceId;

  Task copyWith({
    int? schemaVersion,
    String? id,
    String? userId,
    bool clearUserId = false,
    String? title,
    String? note,
    String? dueDate,
    bool clearDueDate = false,
    Priority? priority,
    Category? category,
    bool? completed,
    String? completedAt,
    bool clearCompletedAt = false,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool clearDeletedAt = false,
    String? createdByDeviceId,
    String? updatedByDeviceId,
  }) {
    return Task(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      userId: clearUserId ? null : (userId ?? this.userId),
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdByDeviceId: createdByDeviceId ?? this.createdByDeviceId,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      schemaVersion: _schemaVersionFromJson(json['schemaVersion']),
      id: _stringOrEmpty(json['id']),
      userId: _nullableString(json['userId']),
      title: _stringOrEmpty(json['title']),
      note: _stringOrEmpty(json['note']),
      dueDate: _nullableString(json['dueDate']),
      priority: _priorityFromJson(_nullableString(json['priority'])),
      category: _categoryFromJson(_nullableString(json['category'])),
      completed: json['completed'] is bool ? json['completed'] as bool : false,
      completedAt: _nullableString(json['completedAt']),
      createdAt: _stringOrEmpty(json['createdAt']),
      updatedAt: _stringOrEmpty(json['updatedAt']),
      deletedAt: _nullableString(json['deletedAt']),
      createdByDeviceId: _stringOrEmpty(json['createdByDeviceId']),
      updatedByDeviceId: _stringOrEmpty(json['updatedByDeviceId']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'userId': userId,
      'title': title,
      'note': note,
      'dueDate': dueDate,
      'priority': priority.name,
      'category': category.name,
      'completed': completed,
      'completedAt': completedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'createdByDeviceId': createdByDeviceId,
      'updatedByDeviceId': updatedByDeviceId,
    };
  }

  static Priority _priorityFromJson(String? value) {
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

  static Category _categoryFromJson(String? value) {
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

  static String _stringOrEmpty(dynamic value) {
    return value is String ? value : '';
  }

  static String? _nullableString(dynamic value) {
    return value is String ? value : null;
  }

  static int _schemaVersionFromJson(dynamic value) {
    return value is int && value > 0 ? value : currentTaskSchemaVersion;
  }
}
