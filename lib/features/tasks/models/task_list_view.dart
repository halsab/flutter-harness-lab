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
  final activeTasks = _sortTasks(
    visibleTasks.where((task) => !task.isCompleted).toList(),
    sort,
  );
  final completedTasks = _sortTasks(
    visibleTasks.where((task) => task.isCompleted).toList(),
    sort,
  );
  return TaskListView(
    tasks: [...activeTasks, ...completedTasks],
    activeTaskCount: tasks.where((task) => !task.isCompleted).length,
  );
}

List<TaskItem> _sortTasks(List<TaskItem> tasks, TaskSort sort) {
  if (sort == TaskSort.defaultOrder) return tasks;
  final indexed = tasks.indexed.toList();
  indexed.sort((a, b) {
    final comparison = _compareTitles(a.$2.title, b.$2.title);
    final directed = sort == TaskSort.ascending ? comparison : -comparison;
    return directed == 0 ? a.$1.compareTo(b.$1) : directed;
  });
  return indexed.map((entry) => entry.$2).toList();
}

const _russianAlphabet = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';

int _compareTitles(String first, String second) {
  final firstRunes = first.toLowerCase().runes.toList();
  final secondRunes = second.toLowerCase().runes.toList();
  final sharedLength = firstRunes.length < secondRunes.length
      ? firstRunes.length
      : secondRunes.length;
  for (var index = 0; index < sharedLength; index++) {
    final firstRank = _titleCharacterRank(firstRunes[index]);
    final secondRank = _titleCharacterRank(secondRunes[index]);
    final comparison = firstRank.compareTo(secondRank);
    if (comparison != 0) return comparison;
  }
  return firstRunes.length.compareTo(secondRunes.length);
}

int _titleCharacterRank(int rune) {
  final character = String.fromCharCode(rune);
  final russianIndex = _russianAlphabet.indexOf(character);
  return russianIndex >= 0 ? russianIndex : rune + _russianAlphabet.length;
}
