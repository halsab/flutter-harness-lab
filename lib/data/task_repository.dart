import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class TaskRepository {
  TaskRepository({SharedPreferences? preferences}) : _preferences = preferences;

  static const _storageKey = 'my_tasks';

  final SharedPreferences? _preferences;

  Future<List<TaskItem>> loadTasks() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final json = preferences.getString(_storageKey);
    if (json == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
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
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }
}
