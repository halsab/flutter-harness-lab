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
  ascending('По названию: А–Я'),
  descending('По названию: Я–А');

  const TaskSort(this.label);
  final String label;
}

class TaskListView {
  const TaskListView({
    required this.tasks,
    required this.activeTasks,
    required this.completedTasks,
    required this.activeTaskCount,
    required this.isAlphabetical,
  });

  final List<TaskItem> tasks;
  final List<TaskItem> activeTasks;
  final List<TaskItem> completedTasks;
  final int activeTaskCount;
  final bool isAlphabetical;
}

String taskQuantity(int count) {
  final lastTwo = count % 100;
  final noun = lastTwo >= 11 && lastTwo <= 14
      ? 'задач'
      : switch (count % 10) {
          1 => 'задача',
          2 || 3 || 4 => 'задачи',
          _ => 'задач',
        };
  return '$count $noun';
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
  final alphabetical = sort != TaskSort.defaultOrder;
  final activeTasks = visibleTasks.where((task) => !task.isCompleted).toList();
  final completedTasks = visibleTasks
      .where((task) => task.isCompleted)
      .toList();
  final displayTasks = filter == TaskFilter.all && !alphabetical
      ? [...activeTasks, ...completedTasks]
      : visibleTasks;
  return TaskListView(
    tasks: displayTasks,
    activeTasks: activeTasks,
    completedTasks: completedTasks,
    activeTaskCount: tasks.where((task) => !task.isCompleted).length,
    isAlphabetical: alphabetical,
  );
}
