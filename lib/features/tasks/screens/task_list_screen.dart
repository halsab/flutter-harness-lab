import 'package:flutter_harness_lab/design_system/design_system.dart';

import '../models/task_item.dart';
import '../view_models/task_list_view.dart';
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
  late final TaskListViewModel _viewModel = widget.viewModel;
  List<TaskItem> get _tasks => _viewModel.tasks;
  bool get _isLoading => _viewModel.isLoading;
  bool get _loadFailed => _viewModel.loadFailed;
  var _shownSaveFailureVersion = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_handleViewModelChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _viewModel.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    if (_shownSaveFailureVersion != _viewModel.saveFailureVersion) {
      _shownSaveFailureVersion = _viewModel.saveFailureVersion;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить задачи')),
      );
    }
    setState(() {});
  }

  Future<void> _loadTasks() => _viewModel.loadTasks();

  Future<void> _addTask() async {
    if (_isLoading || _loadFailed) {
      return;
    }
    final title = _inputController.text.trim();
    final saved = await _viewModel.addTask(title);
    if (saved && mounted && _inputController.text.trim() == title) {
      _inputController.clear();
    }
  }

  void _setTaskCompleted(TaskItem task, bool isCompleted) {
    _viewModel.setTaskCompleted(task, isCompleted);
  }

  void _deleteTask(TaskItem task) => _viewModel.deleteTask(task);

  void _duplicateTask(TaskItem task) => _viewModel.duplicateTask(task);

  Future<void> _deleteCompletedTasks() async {
    if (_isLoading || _loadFailed || !_tasks.any((task) => task.isCompleted)) {
      return;
    }
    final confirmed = usesCupertinoControls
        ? await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Удалить завершённые задачи?'),
              content: const Text('Это действие нельзя отменить.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Удалить'),
                ),
              ],
            ),
          )
        : await showDialog<bool>(
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
      _viewModel.deleteCompletedTasks();
    }
  }

  Widget _buildDeleteCompletedAction() {
    if (!usesCupertinoControls) {
      return TextButton.icon(
        onPressed: _deleteCompletedTasks,
        icon: const Icon(Icons.delete_sweep_outlined),
        label: const Text('Удалить завершённые'),
      );
    }
    return CupertinoButton.tinted(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      foregroundColor: Theme.of(context).colorScheme.error,
      onPressed: _deleteCompletedTasks,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.delete),
          SizedBox(width: AppTheme.spaceXs),
          Text('Удалить завершённые'),
        ],
      ),
    );
  }

  Future<void> _editTask(TaskItem task) async {
    if (_isLoading || _loadFailed) {
      return;
    }
    Widget buildEditDialog(BuildContext context) =>
        EditTaskDialog(initialTitle: task.title);
    final title = usesCupertinoControls
        ? await showCupertinoDialog<String>(
            context: context,
            builder: buildEditDialog,
          )
        : await showDialog<String>(context: context, builder: buildEditDialog);
    if (title == null || !mounted) {
      return;
    }
    _viewModel.renameTask(task, title);
  }

  Widget _buildTitleField(ThemeData theme) {
    if (!usesCupertinoControls) {
      return TextField(
        controller: _inputController,
        enabled: !_isLoading && !_loadFailed,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addTask(),
        decoration: const InputDecoration(
          hintText: 'Например, купить продукты',
          prefixIcon: Icon(Icons.edit_outlined),
        ),
      );
    }
    return CupertinoTextField(
      controller: _inputController,
      enabled: !_isLoading && !_loadFailed,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _addTask(),
      placeholder: 'Например, купить продукты',
      prefix: const Padding(
        padding: EdgeInsets.only(left: AppTheme.spaceMd),
        child: Icon(CupertinoIcons.pencil),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: _cupertinoFieldDecoration(theme),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    if (!usesCupertinoControls) {
      return TextField(
        textInputAction: TextInputAction.search,
        onChanged: _viewModel.setSearchQuery,
        decoration: const InputDecoration(
          hintText: 'Найти задачу',
          prefixIcon: Icon(Icons.search),
        ),
      );
    }
    return CupertinoTextField(
      textInputAction: TextInputAction.search,
      onChanged: _viewModel.setSearchQuery,
      placeholder: 'Найти задачу',
      prefix: const Padding(
        padding: EdgeInsets.only(left: AppTheme.spaceMd),
        child: Icon(CupertinoIcons.search),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: _cupertinoFieldDecoration(theme),
    );
  }

  BoxDecoration _cupertinoFieldDecoration(ThemeData theme) => BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border.all(color: theme.colorScheme.outlineVariant),
    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
  );

  Widget _buildAddButton() {
    final onPressed = _isLoading || _loadFailed ? null : _addTask;
    if (!usesCupertinoControls) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      );
    }
    return CupertinoButton.filled(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.add),
          SizedBox(width: AppTheme.spaceXs),
          Text('Добавить'),
        ],
      ),
    );
  }

  Widget _buildFilterControl() {
    if (!usesCupertinoControls) {
      return Wrap(
        spacing: AppTheme.spaceXs,
        children: [
          for (final filter in TaskFilter.values)
            ChoiceChip(
              label: Text(filter.label),
              selected: _viewModel.taskFilter == filter,
              onSelected: (_) => _viewModel.setTaskFilter(filter),
            ),
        ],
      );
    }
    return CupertinoSlidingSegmentedControl<TaskFilter>(
      groupValue: _viewModel.taskFilter,
      children: {
        for (final filter in TaskFilter.values)
          filter: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXs,
              vertical: AppTheme.spaceSm,
            ),
            child: Text(filter.label),
          ),
      },
      onValueChanged: (filter) {
        if (filter != null) _viewModel.setTaskFilter(filter);
      },
    );
  }

  Widget _buildSortControl() {
    if (!usesCupertinoControls) {
      return DropdownButton<TaskSort>(
        value: _viewModel.taskSort,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        items: [
          for (final sort in TaskSort.values)
            DropdownMenuItem(value: sort, child: Text(sort.label)),
        ],
        onChanged: (sort) {
          if (sort != null) _viewModel.setTaskSort(sort);
        },
      );
    }
    return CupertinoButton(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      onPressed: () => showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Порядок задач'),
          actions: [
            for (final sort in TaskSort.values)
              CupertinoActionSheetAction(
                onPressed: () {
                  _viewModel.setTaskSort(sort);
                  Navigator.of(context).pop();
                },
                child: Text(sort.label),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.sort_down),
          const SizedBox(width: AppTheme.spaceXs),
          Text(_viewModel.taskSort.label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listView = _viewModel.listView;
    final visibleTasks = listView.tasks;
    final activeTaskCount = listView.activeTaskCount;
    final normalizedSearchQuery = _viewModel.searchQuery.trim().toLowerCase();
    final theme = Theme.of(context);
    final content = SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < AppTheme.compactBreakpoint
                    ? AppTheme.compactPageInset
                    : AppTheme.pageInset,
                vertical: AppTheme.spaceXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeHeader(
                    activeTaskCount: activeTaskCount,
                    completedTaskCount: _tasks.length - activeTaskCount,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Text(
                    'ДОБАВИТЬ ВАЖНОЕ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Semantics(
                    identifier: 'task-input',
                    child: _buildTitleField(theme),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      identifier: 'add-task',
                      child: _buildAddButton(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  if (!_isLoading && !_loadFailed) ...[
                    _SectionHeading(
                      eyebrow: 'ВАШ СПИСОК',
                      title: 'Задачи',
                      trailing: _tasks.any((task) => task.isCompleted)
                          ? _buildDeleteCompletedAction()
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Semantics(
                      identifier: 'task-search',
                      child: _buildSearchField(theme),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppTheme.spaceMd,
                      runSpacing: AppTheme.spaceSm,
                      children: [_buildFilterControl(), _buildSortControl()],
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                  ],
                  if (_isLoading)
                    const SizedBox(
                      height: AppTheme.emptyStateHeight,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_loadFailed)
                    SizedBox(
                      height: AppTheme.emptyStateHeight,
                      child: TaskLoadError(onRetry: _loadTasks),
                    )
                  else if (_tasks.isEmpty)
                    SizedBox(
                      height: AppTheme.emptyListHeight,
                      child: const EmptyTasks(),
                    )
                  else if (visibleTasks.isEmpty &&
                      normalizedSearchQuery.isNotEmpty)
                    const SizedBox(
                      height: AppTheme.emptyStateHeight,
                      child: Center(child: Text('Задачи не найдены')),
                    )
                  else if (visibleTasks.isEmpty)
                    SizedBox(
                      height: AppTheme.emptyStateHeight,
                      child: EmptyFilteredTasks(filter: _viewModel.taskFilter),
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
                  const SizedBox(height: AppTheme.space2xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (usesCupertinoControls) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Тихий план')),
        child: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spaceMd),
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: content,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: AppTheme.spaceSm),
            const Text('Тихий план'),
          ],
        ),
        centerTitle: false,
      ),
      body: content,
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.activeTaskCount,
    required this.completedTaskCount,
  });

  final int activeTaskCount;
  final int completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = activeTaskCount + completedTaskCount;
    final progress = total == 0 ? 0.0 : completedTaskCount / total;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space2xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.heroRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ПРОСТРАНСТВО ДЛЯ ВАЖНОГО',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: .78),
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            'Меньше спешки.\nБольше ясности.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              height: 1.08,
              fontSize: AppTheme.heroTitleSize,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.spaceSm),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: theme.colorScheme.onPrimary.withValues(
                      alpha: .2,
                    ),
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Text(
                '$completedTaskCount из $total готово',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            'Незавершённых задач: $activeTaskCount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: .82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: AppTheme.spaceSm,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(title, style: theme.textTheme.titleLarge),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
