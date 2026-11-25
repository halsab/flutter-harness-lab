import 'package:material_ui/material_ui.dart';

import '../../../design_system/design_system.dart';
import '../models/task_item.dart';
import '../models/task_list_view.dart';

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
        const SizedBox(height: AppTokens.space8),
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
          const SizedBox(height: AppTokens.space12),
          Text('Задач пока нет', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTokens.space4),
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: task.isCompleted ? colors.surface : colors.surfaceContainerLow,
      child: ListTile(
        minVerticalPadding: AppTokens.space8,
        contentPadding: const EdgeInsets.only(
          left: AppTokens.space8,
          right: AppTokens.space4,
        ),
        leading: Semantics(
          identifier: 'complete-${task.id}',
          child: Checkbox(
            value: task.isCompleted,
            onChanged: (done) {
              if (done != null) onToggle(done);
            },
          ),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: task.isCompleted
              ? textStyle?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: colors.onSurfaceVariant,
                )
              : textStyle,
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Действия: ${task.title}',
          onSelected: (action) {
            switch (action) {
              case 'edit':
                onEdit();
              case 'duplicate':
                onDuplicate();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Semantics(
                identifier: 'edit-${task.id}',
                child: const ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Изменить'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: Semantics(
                identifier: 'duplicate-${task.id}',
                child: const ListTile(
                  leading: Icon(Icons.content_copy_outlined),
                  title: Text('Дублировать'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Semantics(
                identifier: 'delete-${task.id}',
                child: const ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Удалить'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
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
