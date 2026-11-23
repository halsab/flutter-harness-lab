import 'package:material_ui/material_ui.dart';

import 'data/task_repository.dart';
import 'models/task_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final TaskRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мои задачи',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: TaskListScreen(repository: repository),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, this.repository});

  final TaskRepository? repository;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskRepository _repository = widget.repository ?? TaskRepository();
  final _inputController = TextEditingController();
  var _tasks = <TaskItem>[];
  var _isLoading = true;
  var _loadFailed = false;
  var _taskFilter = _TaskFilter.all;
  final _pendingAddTitles = <String>{};
  Future<void> _pendingWrites = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final tasks = await _repository.loadTasks();
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  void _addTask() {
    if (_isLoading || _loadFailed) {
      return;
    }
    final title = _inputController.text.trim();
    if (title.isEmpty || _pendingAddTitles.contains(title)) {
      return;
    }

    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (_tasks.any((task) => task.id == id)) {
      id = '$id-';
    }

    final task = TaskItem(id: id, title: title);
    _pendingAddTitles.add(title);
    _persistMutation(
      () => _repository.addTask(task),
      onSaved: () {
        _pendingAddTitles.remove(title);
        if (_inputController.text.trim() == title) {
          _inputController.clear();
        }
      },
      onFailure: () => _pendingAddTitles.remove(title),
    );
  }

  void _setTaskCompleted(TaskItem task, bool isCompleted) {
    if (_isLoading || _loadFailed) {
      return;
    }
    _persistMutation(() => _repository.setTaskCompleted(task.id, isCompleted));
  }

  void _deleteTask(TaskItem task) {
    if (_isLoading || _loadFailed) {
      return;
    }
    _persistMutation(() => _repository.deleteTask(task.id));
  }

  Future<void> _editTask(TaskItem task) async {
    if (_isLoading || _loadFailed) {
      return;
    }
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _EditTaskDialog(initialTitle: task.title),
    );
    if (title == null || !mounted) {
      return;
    }
    _persistMutation(() => _repository.renameTask(task.id, title));
  }

  void _persistMutation(
    Future<List<TaskItem>> Function() mutation, {
    VoidCallback? onSaved,
    VoidCallback? onFailure,
  }) {
    _pendingWrites = _pendingWrites
        .then((_) async {
          final savedTasks = await mutation();
          if (mounted) {
            setState(() {
              _tasks = savedTasks;
              onSaved?.call();
            });
          }
        })
        .catchError((Object _) {
          onFailure?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось сохранить задачи')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final activeTaskCount = _tasks.where((task) => !task.isCompleted).length;
    final visibleTasks = _tasks.where((task) {
      return switch (_taskFilter) {
        _TaskFilter.all => true,
        _TaskFilter.active => !task.isCompleted,
        _TaskFilter.completed => task.isCompleted,
      };
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои задачи')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      identifier: 'task-input',
                      child: TextField(
                        controller: _inputController,
                        enabled: !_isLoading && !_loadFailed,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTask(),
                        decoration: const InputDecoration(
                          labelText: 'Новая задача',
                          hintText: 'Например, купить продукты',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        identifier: 'add-task',
                        child: FilledButton.icon(
                          onPressed: _isLoading || _loadFailed
                              ? null
                              : _addTask,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить задачу'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isLoading && !_loadFailed) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final filter in _TaskFilter.values)
                            ChoiceChip(
                              label: Text(filter.label),
                              selected: _taskFilter == filter,
                              onSelected: (_) =>
                                  setState(() => _taskFilter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadFailed)
                      SizedBox(
                        height: 200,
                        child: _TaskLoadError(onRetry: _loadTasks),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Незавершённых задач: $activeTaskCount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_tasks.isEmpty)
                        const SizedBox(height: 240, child: _EmptyTasks())
                      else if (visibleTasks.isEmpty)
                        SizedBox(
                          height: 200,
                          child: _EmptyFilteredTasks(filter: _taskFilter),
                        )
                      else
                        for (final task in visibleTasks)
                          _TaskRow(
                            task: task,
                            onToggle: (isCompleted) =>
                                _setTaskCompleted(task, isCompleted),
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TaskFilter {
  all('Все'),
  active('Активные'),
  completed('Завершённые');

  const _TaskFilter(this.label);

  final String label;
}

class _EmptyFilteredTasks extends StatelessWidget {
  const _EmptyFilteredTasks({required this.filter});

  final _TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _TaskFilter.all => 'Задач пока нет',
      _TaskFilter.active => 'Нет активных задач',
      _TaskFilter.completed => 'Нет завершённых задач',
    };
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TaskLoadError extends StatelessWidget {
  const _TaskLoadError({required this.onRetry});

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

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

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

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Semantics(
              identifier: 'complete-${task.id}',
              child: Checkbox(
                value: task.isCompleted,
                onChanged: (isCompleted) {
                  if (isCompleted != null) {
                    onToggle(isCompleted);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
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
              child: IconButton(
                tooltip: 'Изменить название',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            Semantics(
              identifier: 'delete-${task.id}',
              child: IconButton(
                tooltip: 'Удалить задачу',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
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
