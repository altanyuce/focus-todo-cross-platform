import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../localization/app_strings.dart';
import '../../../settings/presentation/widgets/settings_sheet.dart';
import '../providers/tasks_providers.dart';
import '../state/tasks_ui_state.dart';
import 'tasks_empty_state.dart';
import 'task_filters_sheet.dart';
import 'task_editor_sheet.dart';
import 'task_list_item.dart';

class TasksScreenScaffold extends ConsumerStatefulWidget {
  const TasksScreenScaffold({required this.section, super.key});

  final Section section;

  @override
  ConsumerState<TasksScreenScaffold> createState() =>
      _TasksScreenScaffoldState();
}

class _TasksScreenScaffoldState extends ConsumerState<TasksScreenScaffold> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _scheduleSectionSync();
  }

  @override
  void didUpdateWidget(covariant TasksScreenScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _scheduleSectionSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(tasksProvider);
    final ui = state.ui;
    final tasks = ref.watch(
      sortedVisibleTasksForSectionProvider(widget.section),
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filterCount = _filterCount(ui);
    final activeFilters = _activeFilters(strings, ui);
    final syncConfigured = ref
        .read(tasksProvider.notifier)
        .isManualSyncConfigured();

    _syncSearchValue(ui.search);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(strings.sectionLabel(widget.section)),
            const SizedBox(height: 2),
            Text(
              strings.sectionSubtitle(widget.section),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: _isSyncing || !syncConfigured
                  ? null
                  : () => _runManualSync(context),
              tooltip: 'Şimdi senkronize et',
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.onSurfaceVariant,
                side: BorderSide(color: colors.outlineVariant),
              ),
              icon: Icon(_isSyncing ? Icons.sync : Icons.sync_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _openSettings(context),
              tooltip: strings.settings,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.onSurfaceVariant,
                side: BorderSide(color: colors.outlineVariant),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (String value) {
                                ref
                                    .read(tasksProvider.notifier)
                                    .setUi(search: value);
                              },
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: strings.searchTasks,
                                prefixIcon: const Icon(Icons.search, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonalIcon(
                            onPressed: () => _openFilters(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: filterCount > 0
                                  ? colors.surfaceContainerHigh
                                  : colors.surface,
                              foregroundColor: filterCount > 0
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                              side: BorderSide(
                                color: filterCount > 0
                                    ? colors.outline
                                    : colors.outlineVariant,
                              ),
                            ),
                            icon: Icon(
                              Icons.tune,
                              color: filterCount > 0
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            label: Text(strings.filterCountLabel(filterCount)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openTaskEditor(context),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          strings.quickCapture,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          strings.quickCaptureHint,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (activeFilters.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: activeFilters
                                .map(
                                  (_AppliedFilter appliedFilter) =>
                                      _ActiveFilterChip(
                                        label: appliedFilter.label,
                                        onTap: () => _openFilters(context),
                                      ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? TasksEmptyState(
                      section: widget.section,
                      onAddPressed: () => _openTaskEditor(context),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemBuilder: (BuildContext context, int index) {
                        return TaskListItem(task: tasks[index]);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: tasks.length,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: tasks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openTaskEditor(context),
              elevation: 0,
              highlightElevation: 0,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                strings.addTask,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSectionSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(tasksProvider.notifier).setSection(widget.section);
    });
  }

  void _syncSearchValue(String value) {
    if (_searchController.text == value) {
      return;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _openFilters(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const TaskFiltersSheet();
      },
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const SettingsSheet();
      },
    );
  }

  Future<void> _openTaskEditor(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const TaskEditorSheet();
      },
    );
  }

  Future<void> _runManualSync(BuildContext context) async {
    setState(() {
      _isSyncing = true;
    });

    final result = await ref.read(tasksProvider.notifier).runManualSync();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
    });

    final strings = AppStrings.of(context);
    final message = result.summary.success
        ? strings.syncSucceeded
        : '${strings.syncFailed}: ${result.summary.errorMessage ?? ''}';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _filterCount(TasksUiState ui) {
    return <bool>[
      ui.statusFilter != StatusFilter.all,
      ui.priorityFilter != PriorityFilter.all,
      ui.categoryFilter != CategoryFilter.all,
      ui.sortOrder != SortOrder.defaultOrder,
    ].where((bool value) => value).length;
  }

  List<_AppliedFilter> _activeFilters(AppStrings strings, TasksUiState ui) {
    final filters = <_AppliedFilter>[];

    if (ui.statusFilter != StatusFilter.all) {
      filters.add(
        _AppliedFilter(
          '${strings.status}: ${_statusLabel(strings, ui.statusFilter)}',
        ),
      );
    }

    if (ui.priorityFilter != PriorityFilter.all) {
      filters.add(
        _AppliedFilter(
          '${strings.priority}: ${strings.priorityLabel(ui.priorityFilter.asPriority!)}',
        ),
      );
    }

    if (ui.categoryFilter != CategoryFilter.all) {
      filters.add(
        _AppliedFilter(
          '${strings.list}: ${strings.categoryLabel(ui.categoryFilter.asCategory!)}',
        ),
      );
    }

    if (ui.sortOrder != SortOrder.defaultOrder) {
      filters.add(
        _AppliedFilter('${strings.sort}: ${strings.sortLabel(ui.sortOrder)}'),
      );
    }

    return filters;
  }

  String _statusLabel(AppStrings strings, StatusFilter statusFilter) {
    switch (statusFilter) {
      case StatusFilter.all:
        return strings.all;
      case StatusFilter.active:
        return strings.active;
      case StatusFilter.done:
        return strings.done;
    }
  }
}

class _AppliedFilter {
  const _AppliedFilter(this.label);

  final String label;
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
