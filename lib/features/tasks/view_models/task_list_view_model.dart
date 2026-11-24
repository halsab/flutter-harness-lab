import 'package:flutter/foundation.dart';

import '../models/task_item.dart';
import '../models/task_list_view.dart';
import '../repositories/task_repository.dart';

class TaskListViewModel extends ChangeNotifier {
  TaskListViewModel(this._repository);

  final TaskRepository _repository;
  var _tasks = <TaskItem>[];
  var _isLoading = true;
  var _loadFailed = false;
  var _filter = TaskFilter.all;
  var _searchQuery = '';
  var _sort = TaskSort.defaultOrder;
  var _disposed = false;
  final _pendingAddTitles = <String>{};
  Future<void> _pendingWrites = Future<void>.value();

  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;
  bool get canMutate => !_isLoading && !_loadFailed;
  bool get isEmpty => _tasks.isEmpty;
  bool get hasCompleted => _tasks.any((task) => task.isCompleted);
  TaskFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  TaskSort get sort => _sort;

  TaskListView get listView => deriveTaskListView(
    _tasks,
    filter: _filter,
    searchQuery: _searchQuery,
    sort: _sort,
  );

  void setFilter(TaskFilter value) {
    _filter = value;
    _notify();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _notify();
  }

  void setSort(TaskSort value) {
    _sort = value;
    _notify();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _loadFailed = false;
    _notify();
    try {
      _tasks = await _repository.loadTasks();
      _isLoading = false;
    } on Object {
      _isLoading = false;
      _loadFailed = true;
    }
    _notify();
  }

  void addTask(
    String title, {
    required void Function() onSaved,
    required void Function() onFailure,
  }) {
    if (!canMutate || title.isEmpty || _pendingAddTitles.contains(title)) {
      return;
    }

    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (_tasks.any((task) => task.id == id)) {
      id = '$id-';
    }

    final task = TaskItem(id: id, title: title);
    _pendingAddTitles.add(title);
    _persistMutation(
      () => _repository.addTask(task),
      onSaved: () {
        _pendingAddTitles.remove(title);
        onSaved();
      },
      onFailure: () {
        _pendingAddTitles.remove(title);
        onFailure();
      },
    );
  }

  void setTaskCompleted(
    String id,
    bool isCompleted, {
    required void Function() onFailure,
  }) {
    if (!canMutate) {
      return;
    }
    _persistMutation(
      () => _repository.setTaskCompleted(id, isCompleted),
      onFailure: onFailure,
    );
  }

  void deleteTask(String id, {required void Function() onFailure}) {
    if (!canMutate) {
      return;
    }
    _persistMutation(() => _repository.deleteTask(id), onFailure: onFailure);
  }

  void duplicateTask(String id, {required void Function() onFailure}) {
    if (!canMutate) {
      return;
    }
    _persistMutation(
      () => _repository.duplicateTask(id),
      onFailure: onFailure,
    );
  }

  void deleteCompletedTasks({required void Function() onFailure}) {
    _persistMutation(_repository.deleteCompletedTasks, onFailure: onFailure);
  }

  void renameTask(
    String id,
    String title, {
    required void Function() onFailure,
  }) {
    _persistMutation(
      () => _repository.renameTask(id, title),
      onFailure: onFailure,
    );
  }

  void _persistMutation(
    Future<List<TaskItem>> Function() mutation, {
    void Function()? onSaved,
    required void Function() onFailure,
  }) {
    _pendingWrites = _pendingWrites
        .then((_) async {
          final savedTasks = await mutation();
          if (!_disposed) {
            _tasks = savedTasks;
            onSaved?.call();
            _notify();
          }
        })
        .catchError((Object _) => onFailure());
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
