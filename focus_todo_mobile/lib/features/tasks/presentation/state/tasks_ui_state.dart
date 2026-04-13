import 'package:focus_todo_mobile/shared/models/task.dart';

enum Section { today, upcoming, completed }

enum StatusFilter { all, active, done }

enum PriorityFilter { all, low, medium, high }

enum CategoryFilter { all, personal, work, study }

enum SortOrder {
  defaultOrder,
  dueDateDesc,
  dueDateAsc,
  priorityDesc,
  priorityAsc,
  titleAsc,
  titleDesc,
  createdDesc,
  createdAsc,
}

extension SectionX on Section {
  String get storageValue {
    switch (this) {
      case Section.today:
        return 'today';
      case Section.upcoming:
        return 'upcoming';
      case Section.completed:
        return 'completed';
    }
  }

  static Section fromStorage(String? value) {
    switch (value) {
      case 'upcoming':
        return Section.upcoming;
      case 'completed':
        return Section.completed;
      case 'today':
      default:
        return Section.today;
    }
  }
}

extension StatusFilterX on StatusFilter {
  String get storageValue {
    switch (this) {
      case StatusFilter.all:
        return 'all';
      case StatusFilter.active:
        return 'active';
      case StatusFilter.done:
        return 'done';
    }
  }

  static StatusFilter fromStorage(String? value) {
    switch (value) {
      case 'active':
        return StatusFilter.active;
      case 'done':
        return StatusFilter.done;
      case 'all':
      default:
        return StatusFilter.all;
    }
  }
}

extension PriorityFilterX on PriorityFilter {
  String get storageValue {
    switch (this) {
      case PriorityFilter.all:
        return 'all';
      case PriorityFilter.low:
        return 'low';
      case PriorityFilter.medium:
        return 'medium';
      case PriorityFilter.high:
        return 'high';
    }
  }

  Priority? get asPriority {
    switch (this) {
      case PriorityFilter.all:
        return null;
      case PriorityFilter.low:
        return Priority.low;
      case PriorityFilter.medium:
        return Priority.medium;
      case PriorityFilter.high:
        return Priority.high;
    }
  }

  static PriorityFilter fromStorage(String? value) {
    switch (value) {
      case 'low':
        return PriorityFilter.low;
      case 'medium':
        return PriorityFilter.medium;
      case 'high':
        return PriorityFilter.high;
      case 'all':
      default:
        return PriorityFilter.all;
    }
  }
}

extension CategoryFilterX on CategoryFilter {
  String get storageValue {
    switch (this) {
      case CategoryFilter.all:
        return 'all';
      case CategoryFilter.personal:
        return 'personal';
      case CategoryFilter.work:
        return 'work';
      case CategoryFilter.study:
        return 'study';
    }
  }

  Category? get asCategory {
    switch (this) {
      case CategoryFilter.all:
        return null;
      case CategoryFilter.personal:
        return Category.personal;
      case CategoryFilter.work:
        return Category.work;
      case CategoryFilter.study:
        return Category.study;
    }
  }

  static CategoryFilter fromStorage(String? value) {
    switch (value) {
      case 'personal':
        return CategoryFilter.personal;
      case 'work':
        return CategoryFilter.work;
      case 'study':
        return CategoryFilter.study;
      case 'all':
      default:
        return CategoryFilter.all;
    }
  }
}

extension SortOrderX on SortOrder {
  String get storageValue {
    switch (this) {
      case SortOrder.defaultOrder:
        return 'default';
      case SortOrder.dueDateDesc:
        return 'due-date-desc';
      case SortOrder.dueDateAsc:
        return 'due-date-asc';
      case SortOrder.priorityDesc:
        return 'priority-desc';
      case SortOrder.priorityAsc:
        return 'priority-asc';
      case SortOrder.titleAsc:
        return 'title-asc';
      case SortOrder.titleDesc:
        return 'title-desc';
      case SortOrder.createdDesc:
        return 'created-desc';
      case SortOrder.createdAsc:
        return 'created-asc';
    }
  }

  static SortOrder fromStorage(String? value) {
    switch (value) {
      case 'due-date-desc':
        return SortOrder.dueDateDesc;
      case 'due-date-asc':
        return SortOrder.dueDateAsc;
      case 'priority-desc':
        return SortOrder.priorityDesc;
      case 'priority-asc':
        return SortOrder.priorityAsc;
      case 'title-asc':
        return SortOrder.titleAsc;
      case 'title-desc':
        return SortOrder.titleDesc;
      case 'created-desc':
        return SortOrder.createdDesc;
      case 'created-asc':
        return SortOrder.createdAsc;
      case 'default':
      default:
        return SortOrder.defaultOrder;
    }
  }
}

class TasksUiState {
  const TasksUiState({
    required this.section,
    required this.search,
    required this.statusFilter,
    required this.priorityFilter,
    required this.categoryFilter,
    required this.sortOrder,
  });

  static const TasksUiState initial = TasksUiState(
    section: Section.today,
    search: '',
    statusFilter: StatusFilter.all,
    priorityFilter: PriorityFilter.all,
    categoryFilter: CategoryFilter.all,
    sortOrder: SortOrder.defaultOrder,
  );

  final Section section;
  final String search;
  final StatusFilter statusFilter;
  final PriorityFilter priorityFilter;
  final CategoryFilter categoryFilter;
  final SortOrder sortOrder;

  TasksUiState copyWith({
    Section? section,
    String? search,
    StatusFilter? statusFilter,
    PriorityFilter? priorityFilter,
    CategoryFilter? categoryFilter,
    SortOrder? sortOrder,
  }) {
    return TasksUiState(
      section: section ?? this.section,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'section': section.storageValue,
      'search': search,
      'statusFilter': statusFilter.storageValue,
      'priorityFilter': priorityFilter.storageValue,
      'categoryFilter': categoryFilter.storageValue,
      'sortOrder': sortOrder.storageValue,
    };
  }

  factory TasksUiState.fromJson(Map<String, dynamic> json) {
    return TasksUiState(
      section: SectionX.fromStorage(json['section'] as String?),
      search: json['search'] as String? ?? '',
      statusFilter: StatusFilterX.fromStorage(json['statusFilter'] as String?),
      priorityFilter: PriorityFilterX.fromStorage(
        json['priorityFilter'] as String?,
      ),
      categoryFilter: CategoryFilterX.fromStorage(
        json['categoryFilter'] as String?,
      ),
      sortOrder: SortOrderX.fromStorage(json['sortOrder'] as String?),
    );
  }
}
