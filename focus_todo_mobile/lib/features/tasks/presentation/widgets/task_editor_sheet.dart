import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../localization/app_strings.dart';
import '../../../../shared/models/task.dart';
import '../../domain/queries/task_dates.dart';
import '../providers/tasks_providers.dart';

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({this.task, super.key});

  final Task? task;

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late Priority _priority;
  late Category _category;
  String? _dueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _priority = task?.priority ?? Priority.medium;
    _category = task?.category ?? Category.personal;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isEditing ? strings.editTask : strings.addTask,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_isEditing)
                    TextButton(
                      onPressed: _deleteTask,
                      child: Text(strings.delete),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.title),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: strings.note,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.dueDate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _dueDate == null
                            ? strings.pickDate
                            : MaterialLocalizations.of(
                                context,
                              ).formatShortDate(parseLocalDate(_dueDate!)),
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...<Widget>[
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: strings.clearDate,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Text(
                strings.priority,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Priority.values
                    .map(
                      (Priority priority) => ChoiceChip(
                        label: Text(strings.priorityLabel(priority)),
                        selected: _priority == priority,
                        onSelected: (_) {
                          setState(() {
                            _priority = priority;
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              Text(
                strings.list,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Category.values
                    .map(
                      (Category category) => ChoiceChip(
                        label: Text(strings.categoryLabel(category)),
                        selected: _category == category,
                        onSelected: (_) {
                          setState(() {
                            _category = category;
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveTask,
                      child: Text(strings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initialDate = _dueDate == null
        ? DateTime.now()
        : parseLocalDate(_dueDate!);
    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dueDate = localDateIso(picked);
    });
  }

  void _saveTask() {
    final notifier = ref.read(tasksProvider.notifier);
    final title = _titleController.text;
    final note = _noteController.text;

    if (_isEditing) {
      final original = widget.task!;
      notifier.updateTask(
        original.id,
        title: title.trim().isEmpty ? original.title : title.trim(),
        note: note,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        priority: _priority,
        category: _category,
      );
    } else {
      notifier.addTask(
        title: title,
        note: note,
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _deleteTask() {
    final task = widget.task;
    if (task == null) {
      return;
    }

    ref.read(tasksProvider.notifier).deleteTask(task.id);
    Navigator.of(context).pop();
  }
}
