import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../localization/app_strings.dart';
import '../../../../shared/models/task.dart';
import '../../domain/queries/task_dates.dart';
import '../providers/tasks_providers.dart';
import 'task_editor_sheet.dart';

class TaskListItem extends ConsumerWidget {
  const TaskListItem({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompleted = task.completed;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: isCompleted
          ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72)
          : theme.textTheme.titleMedium?.color,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
    );
    final noteStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isCompleted
          ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
          : theme.textTheme.bodyMedium?.color,
    );
    final priorityColor = _priorityColor(colors, task.priority);

    return Opacity(
      opacity: isCompleted ? 0.8 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Checkbox(
                  value: task.completed,
                  onChanged: (_) {
                    ref.read(tasksProvider.notifier).toggleComplete(task.id);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openEditor(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                          if (task.note.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 5),
                            Text(
                              task.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: noteStyle,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: <Widget>[
                              _MetaChip(
                                label: strings.categoryLabel(task.category),
                              ),
                              _MetaText(
                                icon: Icons.event_outlined,
                                label: _dueLabel(context, strings),
                                faint: task.dueDate == null,
                              ),
                              _MetaText(
                                icon: Icons.flag_outlined,
                                label: strings.priorityLabel(task.priority),
                                color: priorityColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(BuildContext context, AppStrings strings) {
    if (task.dueDate == null) {
      return strings.noDate;
    }

    return MaterialLocalizations.of(
      context,
    ).formatShortDate(parseLocalDate(task.dueDate!));
  }

  Color _priorityColor(ColorScheme colors, Priority priority) {
    switch (priority) {
      case Priority.low:
        return colors.outline;
      case Priority.medium:
        return colors.secondary;
      case Priority.high:
        return colors.primary;
    }
  }

  Future<void> _openEditor(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskEditorSheet(task: task);
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.icon,
    required this.label,
    this.color,
    this.faint = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = faint
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : (color ?? theme.colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: baseColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: baseColor,
            fontStyle: faint ? FontStyle.italic : null,
          ),
        ),
      ],
    );
  }
}
