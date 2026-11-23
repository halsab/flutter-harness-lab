import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class TaskRepository {
  TaskRepository({this.preferences});

  static const _storageKey = 'my_tasks';

  final SharedPreferences? preferences;
  static Future<void> _pendingMutations = Future<void>.value();

  Future<List<TaskItem>> loadTasks() async {
    final storage = preferences ?? await SharedPreferences.getInstance();
    await storage.reload();
    final storedValue = storage.get(_storageKey);
    if (storedValue is! String) {
      return [];
    }

    try {
      final decoded = jsonDecode(storedValue) as List<dynamic>;
      return decoded
          .map(
            (task) => TaskItem.fromJson(Map<String, Object?>.from(task as Map)),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final storage = preferences ?? await SharedPreferences.getInstance();
    final didSave = await storage.setString(
      _storageKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
    if (!didSave) {
      throw StateError('Could not save tasks');
    }
  }

  Future<List<TaskItem>> addTask(TaskItem task) {
    return _mutateTasks((tasks) => [...tasks, task]);
  }

  Future<List<TaskItem>> setTaskCompleted(String taskId, bool isCompleted) {
    return _mutateTasks(
      (tasks) => [
        for (final task in tasks)
          if (task.id == taskId)
            TaskItem(id: task.id, title: task.title, isCompleted: isCompleted)
          else
            task,
      ],
    );
  }

  Future<List<TaskItem>> deleteTask(String taskId) {
    return _mutateTasks(
      (tasks) => tasks.where((task) => task.id != taskId).toList(),
    );
  }

  Future<List<TaskItem>> _mutateTasks(
    List<TaskItem> Function(List<TaskItem>) mutation,
  ) {
    final result = _pendingMutations.then((_) async {
      final currentTasks = await loadTasks();
      final updatedTasks = mutation(currentTasks);
      await saveTasks(updatedTasks);
      return updatedTasks;
    });
    _pendingMutations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
