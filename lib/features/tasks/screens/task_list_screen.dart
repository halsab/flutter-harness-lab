import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../models/task_item.dart';
import '../models/task_list_view.dart';
import '../view_models/task_list_model.dart';
import '../widgets/task_groups.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.model});

  final TaskListModel model;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _revealKey = GlobalKey();
  var _searchDisclosed = false;
  String? _revealId;
  String? _feedback;
  TaskItem? _hiddenTask;

  TaskListModel get _model => widget.model;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_focusChanged);
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {});

  void _openSearch() {
    setState(() => _searchDisclosed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchDisclosed) _searchFocus.requestFocus();
    });
  }

  void _resetSearch({bool close = false}) {
    _search.clear();
    _model.setQuery('');
    if (close) {
      _searchFocus.unfocus();
      setState(() => _searchDisclosed = false);
    }
  }

  // Flutter's Cupertino searchable sliver starts with a visible search field.
  // Keep the real Cupertino search control and use iOS scroll physics to
  // disclose it on a deliberate pull, without disturbing a query or focus.
  bool _onScroll(ScrollNotification event) {
    if (event.depth != 0 ||
        event is! ScrollUpdateNotification ||
        event.dragDetails == null ||
        _searchFocus.hasFocus ||
        _model.hasQuery) {
      return false;
    }
    final offset = event.metrics.pixels - event.metrics.minScrollExtent;
    final delta = event.dragDetails!.delta.dy;
    final reveal = offset < -AppTokens.searchPullDistance && delta > 0;
    final collapse = _searchDisclosed && delta < 0 && offset >= 0;
    if (reveal || collapse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_searchFocus.hasFocus && !_model.hasQuery) {
          setState(() => _searchDisclosed = reveal);
        }
      });
    }
    return false;
  }

  Future<void> _edit([TaskItem? task]) async {
    _searchFocus.unfocus();
    TaskItem? added;
    final saved = await showTitleEditor(
      context,
      title: task == null ? 'Новая задача' : 'Переименовать задачу',
      initialValue: task?.title ?? '',
      confirmLabel: task == null ? 'Добавить' : 'Сохранить',
      onSave: (title) async {
        if (task != null) return _model.rename(task.id, title);
        added = await _model.add(title);
        return added != null;
      },
    );
    if (mounted && saved == true && added != null) {
      _saved(added!, 'Задача добавлена');
    }
  }

  Future<void> _toggle(TaskItem task, bool completed) async {
    final saved = await _model.setCompleted(task.id, completed);
    if (!mounted) return;
    if (!saved) {
      _showFeedback('Не удалось сохранить задачи');
    } else if (!completed) {
      _saved(task, 'Задача снова активна');
    }
  }

  Future<void> _duplicate(TaskItem task) async {
    final copy = await _model.duplicate(task.id);
    if (!mounted) return;
    if (copy == null) {
      _showFeedback('Не удалось сохранить задачи');
    } else {
      _saved(copy, 'Задача дублирована');
    }
  }

  Future<void> _delete([TaskItem? task]) async {
    if (task == null && !_model.canCleanUp) return;
    final confirmed = await confirmAction(
      context,
      title: task == null ? 'Удалить завершённые задачи?' : 'Удалить задачу?',
      message: task == null
          ? 'Будут удалены все завершённые задачи (${_model.completedCount}). '
                'Это действие нельзя отменить.'
          : '«${task.title}» будет удалена. Это действие нельзя отменить.',
      cancelLabel: 'Отмена',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    final saved = task == null
        ? await _model.deleteCompleted()
        : await _model.delete(task.id);
    if (mounted && !saved) _showFeedback('Не удалось сохранить задачи');
  }

  void _saved(TaskItem task, String message) {
    final visible = _model.view.tasks.any((item) => item.id == task.id);
    _showFeedback(visible ? null : message, task: visible ? null : task);
  }

  void _showFeedback(String? message, {TaskItem? task}) => setState(() {
    _feedback = message;
    _hiddenTask = task;
  });

  void _showTask(TaskItem task) {
    _resetSearch(close: true);
    _model.showAll();
    setState(() {
      _revealId = task.id;
      _feedback = null;
      _hiddenTask = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _revealKey.currentContext;
      if (mounted && row != null) {
        Scrollable.ensureVisible(row, duration: AppTokens.disclosureDuration);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) {
      final ios = usesCupertino(context);
      final ready = _model.state == TaskLoadState.ready;
      final view = _model.view;
      return AppPage(
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space20,
              AppTokens.space12,
              AppTokens.space20,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_searchFocus.hasFocus ||
                    constraints.maxHeight > AppTokens.shortViewportHeight)
                  _header(context, view, ready: ready, ios: ios),
                if (ready && (!ios || _searchDisclosed))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space12),
                    child: AppSearchField(
                      controller: _search,
                      focusNode: _searchFocus,
                      onChanged: _model.setQuery,
                      onCancel: () => _resetSearch(close: true),
                    ),
                  ),
                if (_feedback case final message?)
                  _messageBanner(context, message),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: ios ? _onScroll : null,
                    child: SingleChildScrollView(
                      key: const ValueKey('task-list'),
                      physics: appListPhysics(context),
                      padding: const EdgeInsets.only(bottom: AppTokens.space24),
                      child: _content(view),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _header(
    BuildContext context,
    TaskListView view, {
    required bool ready,
    required bool ios,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Мои задачи',
                  style: AppTextStyles.pageTitle(context),
                ),
              ),
              if (ready)
                Text(
                  'Осталось ${taskQuantity(view.activeTaskCount)}',
                  style: AppTextStyles.body(context)
                      .copyWith(color: AppColors.muted(context)),
                ),
            ],
          ),
        ),
        if (ready && ios && !_searchDisclosed)
          AppIconButton(
            symbol: AppSymbol.search,
            label: 'Открыть поиск',
            onPressed: _openSearch,
          ),
        Semantics(
          identifier: 'add-task',
          child: AppIconButton(
            symbol: AppSymbol.add,
            label: 'Добавить задачу',
            filled: true,
            onPressed: ready ? _edit : null,
          ),
        ),
      ],
    ),
  );

  Widget _messageBanner(BuildContext context, String message) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppTokens.radius),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: AppTokens.space12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(liveRegion: true, child: Text(message)),
                if (_hiddenTask case final task?)
                  AppButton(
                    label: 'Показать задачу',
                    primary: false,
                    onPressed: () => _showTask(task),
                  ),
              ],
            ),
          ),
          AppIconButton(
            symbol: AppSymbol.clear,
            label: 'Закрыть сообщение',
            onPressed: () => _showFeedback(null),
          ),
        ],
      ),
    ),
  );

  Widget _content(TaskListView view) => switch (_model.state) {
    TaskLoadState.loading => const Padding(
      padding: AppTokens.pagePadding,
      child: Center(child: AppProgress()),
    ),
    TaskLoadState.failed => AppStateMessage(
      title: 'Не удалось загрузить задачи',
      actionLabel: 'Повторить',
      onAction: _model.load,
    ),
    TaskLoadState.ready => TaskGroups(
      view: view,
      filter: _model.filter,
      sort: _model.sort,
      hasQuery: _model.hasQuery,
      storeEmpty: _model.isEmpty,
      canCleanUp: _model.canCleanUp,
      onFilter: _model.setFilter,
      onSort: _model.setSort,
      onResetSearch: _resetSearch,
      onAdd: _edit,
      onCleanUp: _delete,
      rowBuilder: (task) => TaskListRow(
        key: task.id == _revealId ? _revealKey : ValueKey(task.id),
        task: task,
        onToggle: (value) => _toggle(task, value),
        onEdit: () => _edit(task),
        onDuplicate: () => _duplicate(task),
        onDelete: () => _delete(task),
      ),
    ),
  };
}
