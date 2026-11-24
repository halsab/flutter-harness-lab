import 'task_item.dart';

enum TaskFilter {
  all('Все'),
  active('Активные'),
  completed('Завершённые');

  const TaskFilter(this.label);
  final String label;
}

enum TaskSort {
  defaultOrder('По умолчанию'),
  ascending('А–Я'),
  descending('Я–А');

  const TaskSort(this.label);
  final String label;
}

class TaskListView {
  const TaskListView({required this.tasks, required this.activeTaskCount});

  final List<TaskItem> tasks;
  final int activeTaskCount;
}

TaskListView deriveTaskListView(
  List<TaskItem> tasks, {
  required TaskFilter filter,
  required String searchQuery,
  required TaskSort sort,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final visibleTasks = tasks.where((task) {
    final matchesFilter = switch (filter) {
      TaskFilter.all => true,
      TaskFilter.active => !task.isCompleted,
      TaskFilter.completed => task.isCompleted,
    };
    return matchesFilter && task.title.toLowerCase().contains(normalizedQuery);
  }).toList();
  switch (sort) {
    case TaskSort.defaultOrder:
      break;
    case TaskSort.ascending:
      visibleTasks.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case TaskSort.descending:
      visibleTasks.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
  }
  return TaskListView(
    tasks: visibleTasks,
    activeTaskCount: tasks.where((task) => !task.isCompleted).length,
  );
}
