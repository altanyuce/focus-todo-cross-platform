import '../../../../shared/models/task.dart';
import '../../domain/queries/task_dates.dart';

List<Task> buildSeedTasks() {
  final now = DateTime.now();
  const deviceId = 'seed-device';
  final today = localDateIso(now);
  final yesterday = localDateIso(now.subtract(const Duration(days: 1)));
  final tomorrow = localDateIso(now.add(const Duration(days: 1)));
  final nextWeek = localDateIso(now.add(const Duration(days: 7)));

  String isoHoursAgo(int hours) =>
      now.subtract(Duration(hours: hours)).toUtc().toIso8601String();

  return <Task>[
    Task(
      id: 'task-1',
      title: 'Inbox capture',
      note: 'Undated active tasks must stay in Today.',
      dueDate: null,
      priority: Priority.medium,
      category: Category.personal,
      completed: false,
      completedAt: null,
      createdAt: isoHoursAgo(36),
      updatedAt: isoHoursAgo(36),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
    Task(
      id: 'task-2',
      title: 'Submit status update',
      note: 'Due today should remain in the Today section.',
      dueDate: today,
      priority: Priority.high,
      category: Category.work,
      completed: false,
      completedAt: null,
      createdAt: isoHoursAgo(30),
      updatedAt: isoHoursAgo(28),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
    Task(
      id: 'task-3',
      title: 'Renew transit card',
      note: 'Overdue active tasks also stay in Today.',
      dueDate: yesterday,
      priority: Priority.low,
      category: Category.personal,
      completed: false,
      completedAt: null,
      createdAt: isoHoursAgo(24),
      updatedAt: isoHoursAgo(24),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
    Task(
      id: 'task-4',
      title: 'Review chapter notes',
      note: 'Future dated task should land in Upcoming.',
      dueDate: tomorrow,
      priority: Priority.medium,
      category: Category.study,
      completed: false,
      completedAt: null,
      createdAt: isoHoursAgo(18),
      updatedAt: isoHoursAgo(18),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
    Task(
      id: 'task-5',
      title: 'Plan sprint backlog',
      note: 'Another future task for sorting and filtering checks.',
      dueDate: nextWeek,
      priority: Priority.high,
      category: Category.work,
      completed: false,
      completedAt: null,
      createdAt: isoHoursAgo(12),
      updatedAt: isoHoursAgo(10),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
    Task(
      id: 'task-6',
      title: 'Pay utility bill',
      note: 'Completed tasks must appear only in Completed.',
      dueDate: yesterday,
      priority: Priority.medium,
      category: Category.personal,
      completed: true,
      completedAt: isoHoursAgo(2),
      createdAt: isoHoursAgo(48),
      updatedAt: isoHoursAgo(2),
      deletedAt: null,
      createdByDeviceId: deviceId,
      updatedByDeviceId: deviceId,
    ),
  ];
}
