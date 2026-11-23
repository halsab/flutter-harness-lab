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
    if (title.isEmpty) {
      return;
    }

    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (_tasks.any((task) => task.id == id)) {
      id = '$id-';
    }

    final task = TaskItem(id: id, title: title);
    setState(() => _tasks = [..._tasks, task]);
    _inputController.clear();
    _persistMutation(() => _repository.addTask(task));
  }

  void _toggleTask(TaskItem task) {
    if (_isLoading || _loadFailed) {
      return;
    }
    setState(() {
      _tasks = [
        for (final currentTask in _tasks)
          if (currentTask.id == task.id)
            TaskItem(
              id: currentTask.id,
              title: currentTask.title,
              isCompleted: !currentTask.isCompleted,
            )
          else
            currentTask,
      ];
    });
    _persistMutation(() => _repository.toggleTask(task.id));
  }

  void _deleteTask(TaskItem task) {
    if (_isLoading || _loadFailed) {
      return;
    }
    setState(() {
      _tasks = _tasks
          .where((currentTask) => currentTask.id != task.id)
          .toList();
    });
    _persistMutation(() => _repository.deleteTask(task.id));
  }

  void _persistMutation(Future<List<TaskItem>> Function() mutation) {
    _pendingWrites = _pendingWrites
        .then((_) async {
          final savedTasks = await mutation();
          if (mounted) {
            setState(() => _tasks = savedTasks);
          }
        })
        .catchError((Object _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось сохранить задачи')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
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
                    else if (_tasks.isEmpty)
                      const SizedBox(height: 240, child: _EmptyTasks())
                    else
                      for (final task in _tasks)
                        _TaskRow(
                          task: task,
                          onToggle: () => _toggleTask(task),
                          onDelete: () => _deleteTask(task),
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
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
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
                onChanged: (_) => onToggle(),
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
