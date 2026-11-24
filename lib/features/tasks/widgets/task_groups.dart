import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../models/task_item.dart';
import '../models/task_list_view.dart';

class TaskGroups extends StatelessWidget {
  const TaskGroups({
    super.key,
    required this.view,
    required this.filter,
    required this.sort,
    required this.hasQuery,
    required this.storeEmpty,
    required this.canCleanUp,
    required this.onFilter,
    required this.onSort,
    required this.onResetSearch,
    required this.onAdd,
    required this.onCleanUp,
    required this.rowBuilder,
  });

  final TaskListView view;
  final TaskFilter filter;
  final TaskSort sort;
  final bool hasQuery;
  final bool storeEmpty;
  final bool canCleanUp;
  final ValueChanged<TaskFilter> onFilter;
  final ValueChanged<TaskSort> onSort;
  final VoidCallback onResetSearch;
  final VoidCallback onAdd;
  final VoidCallback onCleanUp;
  final Widget Function(TaskItem) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final grouped = filter == TaskFilter.all && !view.isAlphabetical;
    final active = view.activeTasks;
    final completed = view.completedTasks;
    final sortMenu = AppChoiceMenu(
      label: 'Сортировка',
      symbol: AppSymbol.sort,
      choices: [
        for (final choice in TaskSort.values)
          AppChoice(choice, choice.label, selected: choice == sort),
      ],
      onSelected: onSort,
    );
    final cleanUp = canCleanUp
        ? AppButton(
            label: 'Очистить',
            primary: false,
            onPressed: onCleanUp,
            muted: true,
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!storeEmpty)
          AppSegments(
            choices: {
              for (final scope in TaskFilter.values) scope: scope.label,
            },
            value: filter,
            onChanged: onFilter,
            fallbackLabel: 'Статус',
          ),
        const SizedBox(height: AppTokens.space8),
        if (view.tasks.isEmpty) ...[
          if (!storeEmpty) _SectionHeading(title: null, actions: [sortMenu]),
          _empty(),
        ] else if (grouped) ...[
          if (active.isNotEmpty) ...[
            _SectionHeading(
              title: TaskFilter.active.label,
              actions: [sortMenu],
            ),
            _panel(context, active),
          ],
          if (completed.isNotEmpty) ...[
            if (active.isNotEmpty) const SizedBox(height: AppTokens.sectionGap),
            _SectionHeading(
              title: TaskFilter.completed.label,
              actions: [if (active.isEmpty) sortMenu, ?cleanUp],
            ),
            _panel(context, completed),
          ],
        ] else ...[
          _SectionHeading(
            title: filter == TaskFilter.all ? null : filter.label,
            actions: [sortMenu, if (filter == TaskFilter.completed) ?cleanUp],
          ),
          _panel(context, view.tasks),
          if (filter == TaskFilter.all && cleanUp != null)
            Align(alignment: AlignmentDirectional.centerEnd, child: cleanUp),
        ],
      ],
    );
  }

  Widget _empty() {
    if (hasQuery) {
      return AppStateMessage(
        title: 'Задачи не найдены',
        actionLabel: 'Сбросить поиск',
        onAction: onResetSearch,
      );
    }
    if (storeEmpty) {
      return AppStateMessage(
        title: 'Задач пока нет',
        actionLabel: 'Добавьте первую задачу',
        onAction: onAdd,
      );
    }
    return AppStateMessage(
      title: filter == TaskFilter.active
          ? 'Нет активных задач'
          : 'Нет завершённых задач',
      actionLabel: 'Показать все задачи',
      onAction: () => onFilter(TaskFilter.all),
    );
  }

  Widget _panel(BuildContext context, List<TaskItem> tasks) {
    final inset = usesCupertino(context)
        ? AppTokens.iosTarget
        : AppTokens.materialTarget;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.groupRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsetsDirectional.only(start: inset),
                child: ColoredBox(
                  color: AppColors.divider(context),
                  child: const SizedBox(
                    width: double.infinity,
                    height: AppTokens.dividerHeight,
                  ),
                ),
              ),
            rowBuilder(tasks[i]),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.actions});
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppTokens.iosTarget),
    child: Wrap(
      alignment: title == null ? WrapAlignment.end : WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTokens.space12,
      children: [
        if (title case final text?)
          Semantics(
            header: true,
            child: Text(text, style: AppTextStyles.section(context)),
          ),
        ...actions,
      ],
    ),
  );
}

enum _TaskAction { rename, duplicate, delete }

class TaskListRow extends StatelessWidget {
  const TaskListRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final TaskItem task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = AppTextStyles.listBody(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTokens.rowHeight),
      child: Row(
        children: [
          Semantics(
            identifier: 'complete-${task.id}',
            child: AppCompletionButton(
              label: task.isCompleted
                  ? 'Вернуть в активные: ${task.title}'
                  : 'Завершить: ${task.title}',
              value: task.isCompleted,
              onChanged: onToggle,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
              child: Text(
                task.title,
                style: task.isCompleted
                    ? text.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.muted(context),
                      )
                    : text,
              ),
            ),
          ),
          Semantics(
            identifier: 'actions-${task.id}',
            child: AppChoiceMenu(
              label: 'Действия для ${task.title}',
              symbol: AppSymbol.more,
              choices: const [
                AppChoice(_TaskAction.rename, 'Переименовать'),
                AppChoice(_TaskAction.duplicate, 'Дублировать'),
                AppChoice(_TaskAction.delete, 'Удалить', destructive: true),
              ],
              onSelected: (action) => switch (action) {
                _TaskAction.rename => onEdit(),
                _TaskAction.duplicate => onDuplicate(),
                _TaskAction.delete => onDelete(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
