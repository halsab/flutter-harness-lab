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
  final _searchController = TextEditingController();
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
    _searchController.dispose();
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

  void _setTaskCompleted(TaskItem task, bool isCompleted) =>
      _model.setTaskCompleted(task.id, isCompleted, onFailure: _showWriteError);

  void _deleteTask(TaskItem task) =>
      _model.deleteTask(task.id, onFailure: _showWriteError);

  void _duplicateTask(TaskItem task) =>
      _model.duplicateTask(task.id, onFailure: _showWriteError);

  Future<void> _deleteCompletedTasks() async {
    if (!_model.canMutate || !_model.hasCompleted) return;
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
    if (!_model.canMutate) return;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => EditTaskDialog(initialTitle: task.title),
    );
    if (title != null && mounted) {
      _model.renameTask(task.id, title, onFailure: _showWriteError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listView = _model.listView;
    final visibleTasks = listView.tasks;
    final query = _model.searchQuery.trim().toLowerCase();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои задачи'),
        actions: [
          if (_model.hasCompleted)
            IconButton(
              tooltip: 'Удалить завершённые задачи',
              onPressed: _deleteCompletedTasks,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          Semantics(
            identifier: 'task-sort-menu',
            child: PopupMenuButton<TaskSort>(
              tooltip: 'Сортировка: ${_model.sort.label}',
              icon: const Icon(Icons.sort),
              onSelected: _model.setSort,
              itemBuilder: (context) => [
                for (final sort in TaskSort.values)
                  PopupMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        Expanded(child: Text(sort.label)),
                        if (_model.sort == sort)
                          const Icon(Icons.check, size: 20),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.contentWidth),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space20,
                      AppTokens.space8,
                      AppTokens.space20,
                      AppTokens.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                identifier: 'task-input',
                                child: TextField(
                                  controller: _inputController,
                                  enabled: _model.canMutate,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _addTask(),
                                  decoration: InputDecoration(
                                    hintText: 'Добавить задачу',
                                    prefixIcon: const Icon(Icons.add_task),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTokens.radius,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space8),
                            Semantics(
                              identifier: 'add-task',
                              child: IconButton.filled(
                                tooltip: 'Добавить задачу',
                                onPressed: _model.canMutate ? _addTask : null,
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.space12),
                        Semantics(
                          identifier: 'task-search',
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: _model.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Поиск задач',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _model.searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Очистить поиск',
                                      onPressed: () {
                                        _searchController.clear();
                                        _model.setSearchQuery('');
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        SegmentedButton<TaskFilter>(
                          showSelectedIcon: false,
                          segments: [
                            for (final filter in TaskFilter.values)
                              ButtonSegment(
                                value: filter,
                                label: Text(
                                  filter == TaskFilter.completed
                                      ? 'Готово'
                                      : filter.label,
                                ),
                              ),
                          ],
                          selected: {_model.filter},
                          onSelectionChanged: (selection) {
                            if (selection.isNotEmpty) {
                              _model.setFilter(selection.first);
                            }
                          },
                        ),
                        const SizedBox(height: AppTokens.space16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Незавершённых задач: ${listView.activeTaskCount}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _model.sort.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  else if (_model.isEmpty)
                    const SizedBox(height: 240, child: EmptyTasks())
                  else if (visibleTasks.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          query.isNotEmpty
                              ? 'Задачи не найдены'
                              : _emptyFilterMessage(_model.filter),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    )
                  else
                    for (final task in visibleTasks)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.space12,
                          0,
                          AppTokens.space12,
                          AppTokens.space4,
                        ),
                        child: TaskRow(
                          task: task,
                          onToggle: (done) => _setTaskCompleted(task, done),
                          onEdit: () => _editTask(task),
                          onDelete: () => _deleteTask(task),
                          onDuplicate: () => _duplicateTask(task),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emptyFilterMessage(TaskFilter filter) => switch (filter) {
    TaskFilter.all => 'Задач пока нет',
    TaskFilter.active => 'Нет активных задач',
    TaskFilter.completed => 'Нет завершённых задач',
  };
}
