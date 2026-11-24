import 'package:flutter/foundation.dart';

import '../models/task_item.dart';
import '../models/task_list_view.dart';
import '../repositories/task_repository.dart';

enum TaskLoadState { loading, failed, ready }

class TaskListModel extends ChangeNotifier {
  TaskListModel(this._repository);

  final TaskRepository _repository;
  var _tasks = <TaskItem>[];
  var _state = TaskLoadState.loading;
  var _filter = TaskFilter.all;
  var _sort = TaskSort.defaultOrder;
  var _query = '';
  var _disposed = false;
  final _pendingAddTitles = <String>{};
  Future<void> _writes = Future<void>.value();

  TaskLoadState get state => _state;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  bool get hasQuery => _query.trim().isNotEmpty;
  bool get isEmpty => _tasks.isEmpty;
  int get completedCount => _tasks.where((task) => task.isCompleted).length;
  bool get canCleanUp =>
      !hasQuery && filter != TaskFilter.active && completedCount > 0;
  TaskListView get view => deriveTaskListView(
    _tasks,
    filter: _filter,
    searchQuery: _query,
    sort: _sort,
  );

  Future<void> load() async {
    _state = TaskLoadState.loading;
    _notify();
    try {
      _tasks = await _repository.loadTasks();
      _state = TaskLoadState.ready;
    } on Object {
      _state = TaskLoadState.failed;
    }
    _notify();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    _notify();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    _notify();
  }

  void setQuery(String query) {
    _query = query;
    _notify();
  }

  void showAll() {
    _query = '';
    _filter = TaskFilter.all;
    _notify();
  }

  Future<TaskItem?> add(String draft) async {
    final title = draft.trim();
    if (_state != TaskLoadState.ready ||
        title.isEmpty ||
        !_pendingAddTitles.add(title)) {
      return null;
    }
    try {
      late TaskItem task;
      final saved = await _write(() {
        var id = DateTime.now().microsecondsSinceEpoch.toString();
        while (_tasks.any((task) => task.id == id)) {
          id = '$id-';
        }
        task = TaskItem(id: id, title: title);
        return _repository.addTask(task);
      });
      return saved == null ? null : task;
    } finally {
      _pendingAddTitles.remove(title);
    }
  }

  Future<TaskItem?> duplicate(String id) async {
    final saved = await _write(() => _repository.duplicateTask(id));
    return saved != null && saved.any((task) => task.id == id)
        ? saved.last
        : null;
  }

  Future<bool> rename(String id, String title) async =>
      await _write(() => _repository.renameTask(id, title)) != null;

  Future<bool> setCompleted(String id, bool completed) async =>
      await _write(() => _repository.setTaskCompleted(id, completed)) != null;

  Future<bool> delete(String id) async =>
      await _write(() => _repository.deleteTask(id)) != null;

  Future<bool> deleteCompleted() async =>
      await _write(_repository.deleteCompletedTasks) != null;

  Future<List<TaskItem>?> _write(Future<List<TaskItem>> Function() mutation) {
    if (_state != TaskLoadState.ready) return Future.value();
    final result = _writes.then((_) async {
      try {
        final saved = await mutation();
        _tasks = saved;
        _notify();
        return saved;
      } on Object {
        return null;
      }
    });
    _writes = result.then<void>((_) {});
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
