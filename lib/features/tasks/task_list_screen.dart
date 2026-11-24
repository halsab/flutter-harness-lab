import 'package:material_ui/material_ui.dart';

import '../../data/task_repository.dart';
import '../../models/task_item.dart';
import 'task_list_view.dart';
import 'task_list_widgets.dart';

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
  var _taskFilter = TaskFilter.all;
  var _searchQuery = '';
  var _taskSort = TaskSort.defaultOrder;
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

  void _duplicateTask(TaskItem task) {
    if (_isLoading || _loadFailed) {
      return;
    }
    _persistMutation(() => _repository.duplicateTask(task.id));
  }

  Future<void> _deleteCompletedTasks() async {
    if (_isLoading || _loadFailed || !_tasks.any((task) => task.isCompleted)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить завершённые задачи?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _persistMutation(_repository.deleteCompletedTasks);
    }
  }

  Future<void> _editTask(TaskItem task) async {
    if (_isLoading || _loadFailed) {
      return;
    }
    final title = await showDialog<String>(
      context: context,
      builder: (context) => EditTaskDialog(initialTitle: task.title),
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
    final listView = deriveTaskListView(
      _tasks,
      filter: _taskFilter,
      searchQuery: _searchQuery,
      sort: _taskSort,
    );
    final visibleTasks = listView.tasks;
    final activeTaskCount = listView.activeTaskCount;
    final normalizedSearchQuery = _searchQuery.trim().toLowerCase();
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
                      Semantics(
                        identifier: 'task-search',
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onChanged: (query) =>
                              setState(() => _searchQuery = query),
                          decoration: const InputDecoration(
                            labelText: 'Поиск задач',
                            hintText: 'Введите название задачи',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final filter in TaskFilter.values)
                            ChoiceChip(
                              label: Text(filter.label),
                              selected: _taskFilter == filter,
                              onSelected: (_) =>
                                  setState(() => _taskFilter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TaskSort>(
                        initialValue: _taskSort,
                        decoration: const InputDecoration(
                          labelText: 'Сортировка',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final sort in TaskSort.values)
                            DropdownMenuItem(
                              value: sort,
                              child: Text(sort.label),
                            ),
                        ],
                        onChanged: (sort) {
                          if (sort != null) {
                            setState(() => _taskSort = sort);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_tasks.any((task) => task.isCompleted))
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _deleteCompletedTasks,
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text('Удалить завершённые'),
                          ),
                        ),
                    ],
                    if (_isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadFailed)
                      SizedBox(
                        height: 200,
                        child: TaskLoadError(onRetry: _loadTasks),
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
                        const SizedBox(height: 240, child: EmptyTasks())
                      else if (visibleTasks.isEmpty &&
                          normalizedSearchQuery.isNotEmpty)
                        const SizedBox(
                          height: 200,
                          child: Center(child: Text('Задачи не найдены')),
                        )
                      else if (visibleTasks.isEmpty)
                        SizedBox(
                          height: 200,
                          child: EmptyFilteredTasks(filter: _taskFilter),
                        )
                      else
                        for (final task in visibleTasks)
                          TaskRow(
                            task: task,
                            onToggle: (isCompleted) =>
                                _setTaskCompleted(task, isCompleted),
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task),
                            onDuplicate: () => _duplicateTask(task),
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
