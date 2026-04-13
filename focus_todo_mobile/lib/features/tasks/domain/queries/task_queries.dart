import '../../../../shared/models/task.dart';
import '../../presentation/state/tasks_ui_state.dart';
import 'task_dates.dart';

const List<SortOrder> taskSortOptions = <SortOrder>[
  SortOrder.defaultOrder,
  SortOrder.dueDateDesc,
  SortOrder.dueDateAsc,
  SortOrder.priorityDesc,
  SortOrder.priorityAsc,
  SortOrder.titleAsc,
  SortOrder.titleDesc,
  SortOrder.createdDesc,
  SortOrder.createdAsc,
];

const Map<Priority, int> _priorityOrder = <Priority, int>{
  Priority.low: 0,
  Priority.medium: 1,
  Priority.high: 2,
};

bool matchesSearch(Task task, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }

  return task.title.toLowerCase().contains(normalized) ||
      task.note.toLowerCase().contains(normalized);
}

bool matchesStatus(Task task, StatusFilter filter) {
  switch (filter) {
    case StatusFilter.all:
      return true;
    case StatusFilter.active:
      return !task.completed;
    case StatusFilter.done:
      return task.completed;
  }
}

bool matchesPriority(Task task, PriorityFilter filter) {
  final priority = filter.asPriority;
  if (priority == null) {
    return true;
  }

  return task.priority == priority;
}

bool matchesCategory(Task task, CategoryFilter filter) {
  final category = filter.asCategory;
  if (category == null) {
    return true;
  }

  return task.category == category;
}

List<Task> baseFilters(
  List<Task> tasks, {
  required String search,
  required StatusFilter statusFilter,
  required PriorityFilter priorityFilter,
  required CategoryFilter categoryFilter,
}) {
  return tasks
      .where(
        (Task task) =>
            task.deletedAt == null &&
            matchesSearch(task, search) &&
            matchesStatus(task, statusFilter) &&
            matchesPriority(task, priorityFilter) &&
            matchesCategory(task, categoryFilter),
      )
      .toList(growable: false);
}

bool _inTodayBucket(Task task, String today) {
  if (task.deletedAt != null) {
    return false;
  }
  if (task.completed) {
    return false;
  }
  if (task.dueDate == null) {
    return true;
  }
  return task.dueDate!.compareTo(today) <= 0;
}

bool _inUpcomingBucket(Task task, String today) {
  if (task.deletedAt != null || task.completed || task.dueDate == null) {
    return false;
  }
  return task.dueDate!.compareTo(today) > 0;
}

List<Task> tasksForSection(
  List<Task> tasks, {
  required Section section,
  String? today,
}) {
  final todayValue = today ?? localDateIso();

  switch (section) {
    case Section.today:
      return tasks
          .where((Task task) => _inTodayBucket(task, todayValue))
          .toList(growable: false);
    case Section.upcoming:
      return tasks
          .where((Task task) => _inUpcomingBucket(task, todayValue))
          .toList(growable: false);
    case Section.completed:
      return tasks
          .where((Task task) => task.completed && task.deletedAt == null)
          .toList(growable: false);
  }
}

List<Task> visibleTasks(
  List<Task> tasks, {
  required Section section,
  required String search,
  required StatusFilter statusFilter,
  required PriorityFilter priorityFilter,
  required CategoryFilter categoryFilter,
  String? today,
}) {
  final narrowed = baseFilters(
    tasks,
    search: search,
    statusFilter: statusFilter,
    priorityFilter: priorityFilter,
    categoryFilter: categoryFilter,
  );

  return tasksForSection(narrowed, section: section, today: today);
}

int _compareStrings(String a, String b, {required bool ascending}) {
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  final result = left.compareTo(right);
  return ascending ? result : -result;
}

int _compareTimestamps(String a, String b, {required bool ascending}) {
  final result =
      DateTime.parse(a).millisecondsSinceEpoch -
      DateTime.parse(b).millisecondsSinceEpoch;
  return ascending ? result : -result;
}

int _compareDueDates(
  Task a,
  Task b, {
  required bool ascending,
  required bool missingAtStart,
}) {
  if (a.dueDate == null && b.dueDate == null) {
    return 0;
  }
  if (a.dueDate == null) {
    return missingAtStart ? -1 : 1;
  }
  if (b.dueDate == null) {
    return missingAtStart ? 1 : -1;
  }

  return ascending
      ? a.dueDate!.compareTo(b.dueDate!)
      : b.dueDate!.compareTo(a.dueDate!);
}

int _comparePriority(Task a, Task b, {required bool ascending}) {
  final result = _priorityOrder[a.priority]! - _priorityOrder[b.priority]!;
  return ascending ? result : -result;
}

int _compareDefault(Task a, Task b, {required Section section}) {
  if (section == Section.completed) {
    final completedCompare = _compareTimestamps(
      a.completedAt ?? a.updatedAt,
      b.completedAt ?? b.updatedAt,
      ascending: false,
    );
    if (completedCompare != 0) {
      return completedCompare;
    }
  }

  final dueCompare = _compareDueDates(
    a,
    b,
    ascending: true,
    missingAtStart: true,
  );
  if (dueCompare != 0) {
    return dueCompare;
  }

  final priorityCompare = _comparePriority(a, b, ascending: false);
  if (priorityCompare != 0) {
    return priorityCompare;
  }

  return _compareTimestamps(a.createdAt, b.createdAt, ascending: false);
}

int _compareStableFallback(Task a, Task b) {
  final createdCompare = _compareTimestamps(
    a.createdAt,
    b.createdAt,
    ascending: false,
  );
  if (createdCompare != 0) {
    return createdCompare;
  }

  final titleCompare = _compareStrings(a.title, b.title, ascending: true);
  if (titleCompare != 0) {
    return titleCompare;
  }

  return a.id.compareTo(b.id);
}

int _firstNonZero(Iterable<int> comparisons) {
  for (final int comparison in comparisons) {
    if (comparison != 0) {
      return comparison;
    }
  }

  return 0;
}

int _compareBySortOrder(
  Task a,
  Task b, {
  required Section section,
  required SortOrder sortOrder,
}) {
  switch (sortOrder) {
    case SortOrder.defaultOrder:
      return _compareDefault(a, b, section: section);
    case SortOrder.dueDateDesc:
      return _firstNonZero(<int>[
        _compareDueDates(a, b, ascending: false, missingAtStart: false),
        _comparePriority(a, b, ascending: false),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.dueDateAsc:
      return _firstNonZero(<int>[
        _compareDueDates(a, b, ascending: true, missingAtStart: false),
        _comparePriority(a, b, ascending: false),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.priorityDesc:
      return _firstNonZero(<int>[
        _comparePriority(a, b, ascending: false),
        _compareDueDates(a, b, ascending: true, missingAtStart: false),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.priorityAsc:
      return _firstNonZero(<int>[
        _comparePriority(a, b, ascending: true),
        _compareDueDates(a, b, ascending: true, missingAtStart: false),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.titleAsc:
      return _firstNonZero(<int>[
        _compareStrings(a.title, b.title, ascending: true),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.titleDesc:
      return _firstNonZero(<int>[
        _compareStrings(a.title, b.title, ascending: false),
        _compareStableFallback(a, b),
      ]);
    case SortOrder.createdDesc:
      return _firstNonZero(<int>[
        _compareTimestamps(a.createdAt, b.createdAt, ascending: false),
        _compareStrings(a.title, b.title, ascending: true),
        a.id.compareTo(b.id),
      ]);
    case SortOrder.createdAsc:
      return _firstNonZero(<int>[
        _compareTimestamps(a.createdAt, b.createdAt, ascending: true),
        _compareStrings(a.title, b.title, ascending: true),
        a.id.compareTo(b.id),
      ]);
  }
}

List<Task> sortTasksForDisplay(
  List<Task> tasks, {
  required Section section,
  required SortOrder sortOrder,
}) {
  final result = List<Task>.from(tasks);
  result.sort(
    (Task a, Task b) =>
        _compareBySortOrder(a, b, section: section, sortOrder: sortOrder),
  );
  return result;
}
