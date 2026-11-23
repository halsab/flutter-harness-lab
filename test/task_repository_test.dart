import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_harness_lab/data/task_repository.dart';
import 'package:flutter_harness_lab/models/task_item.dart';

void main() {
  group('TaskRepository', () {
    late SharedPreferences preferences;
    late TaskRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      repository = TaskRepository(preferences: preferences);
    });

    test('loads an empty list when storage has no tasks', () async {
      expect(await repository.loadTasks(), isEmpty);
    });

    test('round-trips task fields including non-Latin text', () async {
      const tasks = [
        TaskItem(
          id: 'task-1',
          title: 'Купить кофе — café ☕',
          isCompleted: true,
        ),
        TaskItem(id: 'task-2', title: 'Read “Dart”'),
      ];

      await repository.saveTasks(tasks);

      final restored = await repository.loadTasks();
      expect(restored, hasLength(2));
      expect(restored[0].id, 'task-1');
      expect(restored[0].title, 'Купить кофе — café ☕');
      expect(restored[0].isCompleted, isTrue);
      expect(restored[1].id, 'task-2');
      expect(restored[1].title, 'Read “Dart”');
      expect(restored[1].isCompleted, isFalse);
    });

    test('recovers from malformed stored JSON', () async {
      await preferences.setString('my_tasks', '{not valid json');

      expect(await repository.loadTasks(), isEmpty);
    });

    test('replaces the previously saved list', () async {
      await repository.saveTasks([
        const TaskItem(id: 'old', title: 'Old task'),
      ]);
      await repository.saveTasks([
        const TaskItem(id: 'new', title: 'New task'),
      ]);

      final restored = await repository.loadTasks();
      expect(restored, hasLength(1));
      expect(restored.single.id, 'new');
    });
  });
}
