import 'package:material_ui/material_ui.dart';

import '../../../design_system/design_system.dart';
import '../models/task_item.dart';
import '../models/task_list_view.dart';
import '../view_models/task_list_view_model.dart';
import '../widgets/task_list_widgets.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.viewModel});

  final TaskListViewModel viewModel;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _inputController = TextEditingController();
  TaskListViewModel get _model => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _model.loadTasks();
  }

  void _onModelChanged() => setState(() {});

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _inputController.dispose();
    super.dispose();
  }

  void _showWriteError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить задачи')),
      );
    }
  }

  void _addTask() {
    final title = _inputController.text.trim();
    _model.addTask(
      title,
      onSaved: () {
        if (mounted && _inputController.text.trim() == title) {
          _inputController.clear();
        }
      },
      onFailure: _showWriteError,
    );
  }

  void _setTaskCompleted(TaskItem task, bool isCompleted) {
    _model.setTaskCompleted(task.id, isCompleted, onFailure: _showWriteError);
  }

  void _deleteTask(TaskItem task) {
    _model.deleteTask(task.id, onFailure: _showWriteError);
  }

  void _duplicateTask(TaskItem task) {
    _model.duplicateTask(task.id, onFailure: _showWriteError);
  }

  Future<void> _deleteCompletedTasks() async {
    if (!_model.canMutate || !_model.hasCompleted) {
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
      _model.deleteCompletedTasks(onFailure: _showWriteError);
    }
  }

  Future<void> _editTask(TaskItem task) async {
    if (!_model.canMutate) {
      return;
    }
    final title = await showDialog<String>(
      context: context,
      builder: (context) => EditTaskDialog(initialTitle: task.title),
    );
    if (title == null || !mounted) {
      return;
    }
    _model.renameTask(task.id, title, onFailure: _showWriteError);
  }

  @override
  Widget build(BuildContext context) {
    final listView = _model.listView;
    final visibleTasks = listView.tasks;
    final activeTaskCount = listView.activeTaskCount;
    final normalizedSearchQuery = _model.searchQuery.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои задачи'), centerTitle: false),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.contentWidth),
            child: Padding(
              padding: AppTokens.pagePadding,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      identifier: 'task-input',
                      child: TextField(
                        controller: _inputController,
                        enabled: _model.canMutate,
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
                    const SizedBox(height: AppTokens.space12),
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        identifier: 'add-task',
                        child: FilledButton.icon(
                          onPressed: _model.canMutate ? _addTask : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить задачу'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space24),
                    if (_model.canMutate) ...[
                      Semantics(
                        identifier: 'task-search',
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onChanged: _model.setSearchQuery,
                          decoration: const InputDecoration(
                            labelText: 'Поиск задач',
                            hintText: 'Введите название задачи',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      Wrap(
                        spacing: AppTokens.space8,
                        children: [
                          for (final filter in TaskFilter.values)
                            ChoiceChip(
                              label: Text(filter.label),
                              selected: _model.filter == filter,
                              onSelected: (_) => _model.setFilter(filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space16),
                      DropdownButtonFormField<TaskSort>(
                        initialValue: _model.sort,
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
                            _model.setSort(sort);
                          }
                        },
                      ),
                      const SizedBox(height: AppTokens.space16),
                      if (_model.hasCompleted)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _deleteCompletedTasks,
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text('Удалить завершённые'),
                          ),
                        ),
                    ],
                    if (_model.isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_model.loadFailed)
                      SizedBox(
                        height: 200,
                        child: TaskLoadError(onRetry: _model.loadTasks),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppTokens.space8,
                          bottom: AppTokens.space12,
                        ),
                        child: Text(
                          'Незавершённых задач: $activeTaskCount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_model.isEmpty)
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
                          child: EmptyFilteredTasks(filter: _model.filter),
                        )
                      else ...[
                        if (visibleTasks.any((task) => !task.isCompleted))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTokens.space8,
                            ),
                            child: Text(
                              'В работе',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        for (final task in visibleTasks.where(
                          (task) => !task.isCompleted,
                        ))
                          TaskRow(
                            task: task,
                            onToggle: (isCompleted) =>
                                _setTaskCompleted(task, isCompleted),
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task),
                            onDuplicate: () => _duplicateTask(task),
                          ),
                        if (_model.filter == TaskFilter.all &&
                            visibleTasks.any((task) => task.isCompleted)) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppTokens.space16,
                              bottom: AppTokens.space12,
                            ),
                            child: Text(
                              'Завершённые · ${visibleTasks.where((task) => task.isCompleted).length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                        for (final task in visibleTasks.where(
                          (task) => task.isCompleted,
                        ))
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
