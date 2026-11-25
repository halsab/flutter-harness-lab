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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchOpen = false;
  TaskListViewModel get _model => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _model.loadTasks();
  }

  void _onModelChanged() => setState(() {});

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    setState(() => _searchOpen = false);
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showWriteError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить задачи')),
      );
    }
  }

  void _openAddTask() {
    if (!_model.canMutate) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddTaskDialog(
        onAdd: (title) => _model.addTask(
          title,
          onSaved: () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          onFailure: _showWriteError,
        ),
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
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
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            tooltip: _searchOpen ? 'Закрыть поиск' : 'Поиск задач',
            onPressed: () {
              if (_searchOpen) {
                _closeSearch();
              } else {
                _openSearch();
              }
            },
            child: Icon(_searchOpen ? Icons.close : Icons.search),
          ),
          const SizedBox(height: AppTokens.space12),
          Semantics(
            identifier: 'add-task',
            child: FloatingActionButton(
              tooltip: 'Добавить задачу',
              onPressed: _model.canMutate ? _openAddTask : null,
              child: const Icon(Icons.add),
            ),
          ),
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
                        if (_searchOpen) ...[
                          const SizedBox(height: AppTokens.space12),
                          Semantics(
                            identifier: 'task-search',
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onChanged: _model.setSearchQuery,
                              decoration: InputDecoration(
                                hintText: 'Поиск задач',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _model.searchQuery.isEmpty
                                    ? IconButton(
                                        tooltip: 'Закрыть поиск',
                                        onPressed: _closeSearch,
                                        icon: const Icon(Icons.close),
                                      )
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
                        ] else if (_model.searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppTokens.space8,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InputChip(
                                avatar: const Icon(Icons.search, size: 18),
                                label: Text(_model.searchQuery),
                                onPressed: _openSearch,
                                onDeleted: () {
                                  _searchController.clear();
                                  _model.setSearchQuery('');
                                },
                                deleteButtonTooltipMessage: 'Очистить поиск',
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
                            MenuAnchor(
                              menuChildren: [
                                for (final sort in TaskSort.values)
                                  MenuItemButton(
                                    onPressed: () => _model.setSort(sort),
                                    trailingIcon: _model.sort == sort
                                        ? const Icon(Icons.check)
                                        : null,
                                    child: Text(sort.label),
                                  ),
                              ],
                              builder: (context, controller, child) =>
                                  Semantics(
                                    identifier: 'task-sort-menu',
                                    button: true,
                                    label: 'Сортировка: ${_model.sort.label}',
                                    child: TextButton.icon(
                                      onPressed: controller.open,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                      label: Text(
                                        _model.sort.label,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
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
