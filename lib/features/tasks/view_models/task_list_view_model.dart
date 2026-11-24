import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import 'task_list_view.dart';

class TaskListViewModel extends ChangeNotifier {
  TaskListViewModel(this._repository);

  final TaskRepository _repository;
  final _pendingAddTitles = <String>{};
  Future<void> _pendingWrites = Future<void>.value();
  List<TaskItem> tasks = [];
  bool isLoading = true;
  bool loadFailed = false;
  int saveFailureVersion = 0;
  TaskFilter taskFilter = TaskFilter.all;
  String searchQuery = '';
  TaskSort taskSort = TaskSort.defaultOrder;

  TaskListView get listView => deriveTaskListView(
    tasks,
    filter: taskFilter,
    searchQuery: searchQuery,
    sort: taskSort,
  );

  void setTaskFilter(TaskFilter filter) {
    taskFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setTaskSort(TaskSort sort) {
    taskSort = sort;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    isLoading = true;
    loadFailed = false;
    notifyListeners();
    try {
      tasks = await _repository.loadTasks();
      isLoading = false;
    } on Object {
      isLoading = false;
      loadFailed = true;
    }
    notifyListeners();
  }

  Future<bool> addTask(String title) async {
    if (isLoading ||
        loadFailed ||
        title.isEmpty ||
        !_pendingAddTitles.add(title)) {
      return false;
    }
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (tasks.any((task) => task.id == id)) {
      id = '$id-';
    }
    final saved = Completer<bool>();
    await _persistMutation(
      () => _repository.addTask(TaskItem(id: id, title: title)),
      onSaved: () {
        _pendingAddTitles.remove(title);
        saved.complete(true);
      },
      onFailure: () {
        _pendingAddTitles.remove(title);
        saved.complete(false);
      },
    );
    return saved.future;
  }

  void setTaskCompleted(TaskItem task, bool isCompleted) {
    if (!_canMutate) return;
    unawaited(
      _persistMutation(
        () => _repository.setTaskCompleted(task.id, isCompleted),
      ),
    );
  }

  void deleteTask(TaskItem task) {
    if (!_canMutate) return;
    unawaited(_persistMutation(() => _repository.deleteTask(task.id)));
  }

  void duplicateTask(TaskItem task) {
    if (!_canMutate) return;
    unawaited(_persistMutation(() => _repository.duplicateTask(task.id)));
  }

  void deleteCompletedTasks() {
    if (!_canMutate || !tasks.any((task) => task.isCompleted)) return;
    unawaited(_persistMutation(_repository.deleteCompletedTasks));
  }

  void renameTask(TaskItem task, String title) {
    if (!_canMutate) return;
    unawaited(_persistMutation(() => _repository.renameTask(task.id, title)));
  }

  bool get _canMutate => !isLoading && !loadFailed;

  Future<void> _persistMutation(
    Future<List<TaskItem>> Function() mutation, {
    VoidCallback? onSaved,
    VoidCallback? onFailure,
  }) async {
    final nextWrite = _pendingWrites.then((_) async {
      try {
        tasks = await mutation();
        onSaved?.call();
        notifyListeners();
      } on Object {
        onFailure?.call();
        saveFailureVersion++;
        notifyListeners();
      }
    });
    _pendingWrites = nextWrite;
    await nextWrite;
  }
}
