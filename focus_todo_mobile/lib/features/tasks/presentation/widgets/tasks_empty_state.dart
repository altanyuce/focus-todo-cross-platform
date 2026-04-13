import 'package:flutter/material.dart';

import '../../../../localization/app_strings.dart';
import '../state/tasks_ui_state.dart';

class TasksEmptyState extends StatelessWidget {
  const TasksEmptyState({
    required this.section,
    required this.onAddPressed,
    super.key,
  });

  final Section section;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Icon(
                          _iconForSection(section),
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.emptySectionLabel(section),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.emptySectionPrompt(section),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: onAddPressed,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(strings.addTask),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForSection(Section section) {
    switch (section) {
      case Section.today:
        return Icons.today_outlined;
      case Section.upcoming:
        return Icons.event_outlined;
      case Section.completed:
        return Icons.task_alt_outlined;
    }
  }
}
