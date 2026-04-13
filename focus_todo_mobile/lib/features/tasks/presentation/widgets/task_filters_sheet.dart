import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/queries/task_queries.dart';
import '../providers/tasks_providers.dart';
import '../state/tasks_ui_state.dart';

class TaskFiltersSheet extends ConsumerWidget {
  const TaskFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final state = ref.watch(tasksProvider);
    final ui = state.ui;
    final notifier = ref.read(tasksProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      strings.filtersSort,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      notifier.setUi(
                        statusFilter: StatusFilter.all,
                        priorityFilter: PriorityFilter.all,
                        categoryFilter: CategoryFilter.all,
                        sortOrder: SortOrder.defaultOrder,
                      );
                    },
                    child: Text(strings.reset),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(strings.filtersHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              _SheetSection(
                title: strings.status,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _Choice(
                      label: strings.all,
                      selected: ui.statusFilter == StatusFilter.all,
                      onSelected: () =>
                          notifier.setUi(statusFilter: StatusFilter.all),
                    ),
                    _Choice(
                      label: strings.active,
                      selected: ui.statusFilter == StatusFilter.active,
                      onSelected: () =>
                          notifier.setUi(statusFilter: StatusFilter.active),
                    ),
                    _Choice(
                      label: strings.done,
                      selected: ui.statusFilter == StatusFilter.done,
                      onSelected: () =>
                          notifier.setUi(statusFilter: StatusFilter.done),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SheetSection(
                title: strings.priority,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _Choice(
                      label: strings.any,
                      selected: ui.priorityFilter == PriorityFilter.all,
                      onSelected: () =>
                          notifier.setUi(priorityFilter: PriorityFilter.all),
                    ),
                    _Choice(
                      label: strings.priorityLabel(
                        PriorityFilter.low.asPriority!,
                      ),
                      selected: ui.priorityFilter == PriorityFilter.low,
                      onSelected: () =>
                          notifier.setUi(priorityFilter: PriorityFilter.low),
                    ),
                    _Choice(
                      label: strings.priorityLabel(
                        PriorityFilter.medium.asPriority!,
                      ),
                      selected: ui.priorityFilter == PriorityFilter.medium,
                      onSelected: () =>
                          notifier.setUi(priorityFilter: PriorityFilter.medium),
                    ),
                    _Choice(
                      label: strings.priorityLabel(
                        PriorityFilter.high.asPriority!,
                      ),
                      selected: ui.priorityFilter == PriorityFilter.high,
                      onSelected: () =>
                          notifier.setUi(priorityFilter: PriorityFilter.high),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SheetSection(
                title: strings.list,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _Choice(
                      label: strings.allLists,
                      selected: ui.categoryFilter == CategoryFilter.all,
                      onSelected: () =>
                          notifier.setUi(categoryFilter: CategoryFilter.all),
                    ),
                    _Choice(
                      label: strings.categoryLabel(
                        CategoryFilter.personal.asCategory!,
                      ),
                      selected: ui.categoryFilter == CategoryFilter.personal,
                      onSelected: () => notifier.setUi(
                        categoryFilter: CategoryFilter.personal,
                      ),
                    ),
                    _Choice(
                      label: strings.categoryLabel(
                        CategoryFilter.work.asCategory!,
                      ),
                      selected: ui.categoryFilter == CategoryFilter.work,
                      onSelected: () =>
                          notifier.setUi(categoryFilter: CategoryFilter.work),
                    ),
                    _Choice(
                      label: strings.categoryLabel(
                        CategoryFilter.study.asCategory!,
                      ),
                      selected: ui.categoryFilter == CategoryFilter.study,
                      onSelected: () =>
                          notifier.setUi(categoryFilter: CategoryFilter.study),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SheetSection(
                title: strings.sort,
                child: Column(
                  children: taskSortOptions
                      .map(
                        (SortOrder option) => RadioListTile<SortOrder>(
                          contentPadding: EdgeInsets.zero,
                          value: option,
                          groupValue: ui.sortOrder,
                          title: Text(strings.sortLabel(option)),
                          onChanged: (SortOrder? value) {
                            if (value != null) {
                              notifier.setUi(sortOrder: value);
                            }
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
