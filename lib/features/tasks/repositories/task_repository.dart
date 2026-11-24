import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class TaskRepository {
  TaskRepository({this.preferences});

  static const _storageKey = 'my_tasks';

  final SharedPreferences? preferences;
  static Future<void>? _pendingMutations;

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

  Future<List<TaskItem>> duplicateTask(String taskId) {
    return _mutateTasks((tasks) {
      final sourceIndex = tasks.indexWhere((task) => task.id == taskId);
      if (sourceIndex == -1) {
        return tasks;
      }
      final source = tasks[sourceIndex];

      var duplicateId = DateTime.now().microsecondsSinceEpoch.toString();
      while (tasks.any((task) => task.id == duplicateId)) {
        duplicateId = '$duplicateId-';
      }

      return [...tasks, TaskItem(id: duplicateId, title: source.title)];
    });
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

  Future<List<TaskItem>> renameTask(String taskId, String title) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return Future.error(ArgumentError.value(title, 'title'));
    }
    return _mutateTasks(
      (tasks) => [
        for (final task in tasks)
          if (task.id == taskId)
            TaskItem(
              id: task.id,
              title: normalizedTitle,
              isCompleted: task.isCompleted,
            )
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

  Future<List<TaskItem>> deleteCompletedTasks() {
    return _mutateTasks(
      (tasks) => tasks.where((task) => !task.isCompleted).toList(),
    );
  }

  Future<List<TaskItem>> _mutateTasks(
    List<TaskItem> Function(List<TaskItem>) mutation,
  ) {
    final previous = _pendingMutations ?? Future<void>.value();
    final result = previous.then((_) async {
      final currentTasks = await loadTasks();
      final updatedTasks = mutation(currentTasks);
      await saveTasks(updatedTasks);
      return updatedTasks;
    });
    late final Future<void> tail;
    void clearIfIdle() {
      if (identical(_pendingMutations, tail)) _pendingMutations = null;
    }

    // Do not retain an idle Future owned by a caller's zone.
    tail = result.then<void>(
      (_) => clearIfIdle(),
      onError: (Object _) {
        clearIfIdle();
      },
    );
    _pendingMutations = tail;
    return result;
  }
}
