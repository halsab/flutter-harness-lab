import 'task_item.dart';

enum TaskFilter {
  all('Все'),
  active('Активные'),
  completed('Завершённые');

  const TaskFilter(this.label);
  final String label;
}

enum TaskSort {
  defaultOrder('По добавлению'),
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
  final queryWords = searchQuery
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final visibleTasks = tasks.where((task) {
    final matchesFilter = switch (filter) {
      TaskFilter.all => true,
      TaskFilter.active => !task.isCompleted,
      TaskFilter.completed => task.isCompleted,
    };
    final normalizedTitle = task.title.toLowerCase();
    final matchesSearch = queryWords.every(normalizedTitle.contains);
    return matchesFilter && matchesSearch;
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
