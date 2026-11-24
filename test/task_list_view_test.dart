import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_harness_lab/features/tasks/models/task_item.dart';
import 'package:flutter_harness_lab/features/tasks/models/task_list_view.dart';

void main() {
  const tasks = [
    TaskItem(id: 'b', title: 'B'),
    TaskItem(id: 'e', title: 'E', isCompleted: true),
    TaskItem(id: 'a', title: 'A'),
    TaskItem(id: 'f', title: 'F', isCompleted: true),
    TaskItem(id: 'c', title: 'C'),
    TaskItem(id: 'd', title: 'D', isCompleted: true),
  ];

  test('sorts independently within active and completed groups', () {
    final ascending = deriveTaskListView(
      tasks,
      filter: TaskFilter.all,
      searchQuery: '',
      sort: TaskSort.ascending,
    );
    expect(ascending.tasks.map((task) => task.title), [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]);

    final descending = deriveTaskListView(
      tasks,
      filter: TaskFilter.all,
      searchQuery: '',
      sort: TaskSort.descending,
    );
    expect(descending.tasks.map((task) => task.title), [
      'C',
      'B',
      'A',
      'F',
      'E',
      'D',
    ]);
    expect(tasks.map((task) => task.title), ['B', 'E', 'A', 'F', 'C', 'D']);
  });

  test('combines query and status filter without flattening groups', () {
    final result = deriveTaskListView(
      tasks,
      filter: TaskFilter.all,
      searchQuery: ' d ',
      sort: TaskSort.ascending,
    );
    expect(result.tasks.map((task) => task.title), ['D']);
    expect(result.activeTaskCount, 3);

    final activeOnly = deriveTaskListView(
      tasks,
      filter: TaskFilter.active,
      searchQuery: '',
      sort: TaskSort.ascending,
    );
    expect(activeOnly.tasks.map((task) => task.title), ['A', 'B', 'C']);
  });

  test('keeps equal-title tasks in their stored order in either direction', () {
    const duplicates = [
      TaskItem(id: 'first', title: 'same'),
      TaskItem(id: 'second', title: 'SAME'),
    ];
    for (final sort in [TaskSort.ascending, TaskSort.descending]) {
      final result = deriveTaskListView(
        duplicates,
        filter: TaskFilter.all,
        searchQuery: '',
        sort: sort,
      );
      expect(result.tasks.map((task) => task.id), ['first', 'second']);
    }
  });

  test('sorts Russian titles with Ё immediately after Е', () {
    const russianTitles = [
      TaskItem(id: 'ya', title: 'Ящик'),
      TaskItem(id: 'yo', title: 'Ёлка'),
      TaskItem(id: 'zh', title: 'Жук'),
      TaskItem(id: 'e', title: 'Ель'),
    ];
    final ascending = deriveTaskListView(
      russianTitles,
      filter: TaskFilter.all,
      searchQuery: '',
      sort: TaskSort.ascending,
    );
    expect(ascending.tasks.map((task) => task.id), ['e', 'yo', 'zh', 'ya']);

    final descending = deriveTaskListView(
      russianTitles,
      filter: TaskFilter.all,
      searchQuery: '',
      sort: TaskSort.descending,
    );
    expect(descending.tasks.map((task) => task.id), ['ya', 'zh', 'yo', 'e']);
  });
}
