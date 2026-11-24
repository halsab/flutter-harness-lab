import 'package:flutter_harness_lab/design_system/design_system.dart';

import '../models/task_item.dart';
import '../view_models/task_list_view.dart';

class EmptyFilteredTasks extends StatelessWidget {
  const EmptyFilteredTasks({super.key, required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      TaskFilter.all => 'Задач пока нет',
      TaskFilter.active => 'Нет активных задач',
      TaskFilter.completed => 'Нет завершённых задач',
    };
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class TaskLoadError extends StatelessWidget {
  const TaskLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Не удалось загрузить задачи'),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    );
  }
}

class EmptyTasks extends StatelessWidget {
  const EmptyTasks({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('Задач пока нет', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Добавьте первую задачу',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  final TaskItem task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.taskRowInset,
          vertical: AppTheme.taskRowPadding,
        ),
        child: Row(
          children: [
            Semantics(
              identifier: 'complete-${task.id}',
              child: usesCupertinoControls
                  ? CupertinoCheckbox(
                      value: task.isCompleted,
                      onChanged: (isCompleted) {
                        if (isCompleted != null) onToggle(isCompleted);
                      },
                    )
                  : Checkbox(
                      value: task.isCompleted,
                      onChanged: (isCompleted) {
                        if (isCompleted != null) {
                          onToggle(isCompleted);
                        }
                      },
                    ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: task.isCompleted
                    ? textStyle?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.outline,
                      )
                    : textStyle,
              ),
            ),
            Semantics(
              identifier: 'edit-${task.id}',
              label: 'Изменить название',
              button: true,
              child: _actionButton(
                tooltip: 'Изменить название',
                onPressed: onEdit,
                materialIcon: Icons.edit_outlined,
                cupertinoIcon: CupertinoIcons.pencil,
              ),
            ),
            Semantics(
              identifier: 'duplicate-${task.id}',
              label: 'Дублировать задачу',
              button: true,
              child: _actionButton(
                tooltip: 'Дублировать задачу',
                onPressed: onDuplicate,
                materialIcon: Icons.content_copy_outlined,
                cupertinoIcon: CupertinoIcons.doc_on_doc,
              ),
            ),
            Semantics(
              identifier: 'delete-${task.id}',
              label: 'Удалить задачу',
              button: true,
              child: _actionButton(
                tooltip: 'Удалить задачу',
                onPressed: onDelete,
                materialIcon: Icons.delete_outline,
                cupertinoIcon: CupertinoIcons.delete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String tooltip,
    required VoidCallback onPressed,
    required IconData materialIcon,
    required IconData cupertinoIcon,
  }) {
    if (!usesCupertinoControls) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(materialIcon),
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Semantics(
        label: tooltip,
        button: true,
        child: Icon(cupertinoIcon),
      ),
    );
  }
}

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({super.key, required this.initialTitle});

  final String initialTitle;

  @override
  State<EditTaskDialog> createState() => EditTaskDialogState();
}

class EditTaskDialogState extends State<EditTaskDialog> {
  late final _controller = TextEditingController(text: widget.initialTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usesCupertinoControls) {
      return CupertinoAlertDialog(
        title: const Text('Изменить название задачи'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppTheme.spaceMd),
          child: CupertinoTextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(context),
            placeholder: 'Название задачи',
            padding: const EdgeInsets.all(AppTheme.spaceMd),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => _save(context),
            child: const Text('Сохранить'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Изменить название задачи'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(context),
        decoration: const InputDecoration(labelText: 'Название задачи'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => _save(context),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      Navigator.of(context).pop(title);
    }
  }
}
