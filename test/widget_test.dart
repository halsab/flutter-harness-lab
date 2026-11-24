import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_harness_lab/app/app.dart';
import 'package:flutter_harness_lab/design_system/design_system.dart';
import 'package:flutter_harness_lab/features/tasks/models/task_item.dart';
import 'package:flutter_harness_lab/features/tasks/repositories/task_repository.dart';

Finder get _taskInputField => find.descendant(
  of: find.bySemanticsIdentifier('task-input'),
  matching: find.byType(TextField),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late TaskRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    repository = TaskRepository(preferences: preferences);
  });

  testWidgets('shows an empty state and rejects blank task titles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Задач пока нет'), findsOneWidget);
    expect(find.text('Добавьте первую задачу'), findsOneWidget);
    expect(find.text('Незавершённых задач: 0'), findsOneWidget);

    final input = find.bySemanticsIdentifier('task-input');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pump();
    expect(find.text('Задач пока нет'), findsOneWidget);

    await tester.enterText(input, '   ');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pump();

    expect(find.text('Задач пока нет'), findsOneWidget);
    expect(await repository.loadTasks(), isEmpty);
    semantics.dispose();
  });

  testWidgets('uses native iOS controls below the navigation bar', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await repository.saveTasks([
      const TaskItem(id: 'ios-task', title: 'Задача на iPhone'),
      const TaskItem(
        id: 'ios-completed',
        title: 'Завершённая задача',
        isCompleted: true,
      ),
    ]);

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    final navigationBar = find.byType(CupertinoNavigationBar);
    expect(find.byType(CupertinoPageScaffold), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('ПРОСТРАНСТВО ДЛЯ ВАЖНОГО')).dy,
      greaterThanOrEqualTo(tester.getBottomRight(navigationBar).dy),
    );
    expect(
      find.widgetWithText(CupertinoButton, 'Удалить завершённые'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, 'Удалить завершённые'),
      findsNothing,
    );

    await tester.ensureVisible(find.bySemanticsIdentifier('edit-ios-task'));
    await tester.tap(find.bySemanticsIdentifier('edit-ios-task'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters tasks without changing their saved status', (
    tester,
  ) async {
    final filterRepository = _EditableTaskRepository([
      const TaskItem(id: 'active', title: 'Active task'),
      const TaskItem(
        id: 'completed',
        title: 'Completed task',
        isCompleted: true,
      ),
    ]);
    await tester.pumpWidget(MyApp(repository: filterRepository));
    await tester.pumpAndSettle();

    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Незавершённых задач: 1'), findsOneWidget);

    await _tapVisible(tester, find.text('Активные'));
    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);

    await _tapVisible(tester, find.text('Завершённые'));
    expect(find.text('Active task'), findsNothing);
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Незавершённых задач: 1'), findsOneWidget);

    await _tapVisible(tester, find.text('Все'));
    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsOneWidget);
    expect(filterRepository.tasks.map((task) => task.isCompleted), [
      false,
      true,
    ]);
  });

  testWidgets('shows a helpful empty state for an empty filter', (
    tester,
  ) async {
    final filterRepository = _EditableTaskRepository([
      const TaskItem(
        id: 'completed',
        title: 'Completed task',
        isCompleted: true,
      ),
    ]);
    await tester.pumpWidget(MyApp(repository: filterRepository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Активные'));
    expect(find.text('Нет активных задач'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);
    expect((await filterRepository.loadTasks()).single.isCompleted, isTrue);
  });

  testWidgets('deletes all completed tasks regardless of filter and search', (
    tester,
  ) async {
    final deleteRepository = _EditableTaskRepository([
      const TaskItem(id: 'active', title: 'Keep this active task'),
      const TaskItem(
        id: 'completed-visible',
        title: 'Matching completed task',
        isCompleted: true,
      ),
      const TaskItem(
        id: 'completed-hidden',
        title: 'Other completed task',
        isCompleted: true,
      ),
    ]);
    await tester.pumpWidget(MyApp(repository: deleteRepository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsIdentifier('task-search'),
      'Matching',
    );
    await _tapVisible(tester, find.text('Активные'));

    await _tapVisible(tester, find.text('Удалить завершённые'));
    expect(find.text('Удалить завершённые задачи?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(deleteRepository.tasks, hasLength(3));

    await _tapVisible(tester, find.text('Удалить завершённые'));
    await _tapVisible(tester, find.text('Удалить').last);

    expect(deleteRepository.tasks.map((task) => task.id), ['active']);
    expect(find.text('Keep this active task'), findsNothing);
    expect(find.text('Незавершённых задач: 1'), findsOneWidget);
  });

  testWidgets('keeps tasks unchanged when bulk deletion cannot be saved', (
    tester,
  ) async {
    final failedRepository = _FailingCompletedDeleteRepository([
      const TaskItem(id: 'active', title: 'Keep this task'),
      const TaskItem(
        id: 'completed',
        title: 'Do not delete on failure',
        isCompleted: true,
      ),
    ]);
    await tester.pumpWidget(MyApp(repository: failedRepository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Удалить завершённые'));
    await _tapVisible(tester, find.text('Удалить').last);

    expect(failedRepository.tasks.map((task) => task.id), [
      'active',
      'completed',
    ]);
    expect(find.text('Keep this task'), findsOneWidget);
    expect(find.text('Do not delete on failure'), findsOneWidget);
    expect(find.text('Не удалось сохранить задачи'), findsOneWidget);
  });

  testWidgets('searches titles case-insensitively and combines with filters', (
    tester,
  ) async {
    final searchRepository = _EditableTaskRepository([
      const TaskItem(id: 'active', title: 'Buy Milk'),
      const TaskItem(id: 'completed', title: 'MILK the cow', isCompleted: true),
      const TaskItem(id: 'other', title: 'Read a book'),
    ]);
    await tester.pumpWidget(MyApp(repository: searchRepository));
    await tester.pumpAndSettle();

    final search = find.bySemanticsIdentifier('task-search');
    await tester.enterText(search, 'milk');
    await tester.pump();
    expect(find.text('Buy Milk'), findsOneWidget);
    expect(find.text('MILK the cow'), findsOneWidget);
    expect(find.text('Read a book'), findsNothing);
    expect(find.text('Незавершённых задач: 2'), findsOneWidget);

    await _tapVisible(tester, find.text('Завершённые'));
    expect(find.text('Buy Milk'), findsNothing);
    expect(find.text('MILK the cow'), findsOneWidget);
    expect(find.text('Незавершённых задач: 2'), findsOneWidget);

    await tester.enterText(search, 'missing');
    await tester.pump();
    expect(find.text('Задачи не найдены'), findsOneWidget);
    expect((await searchRepository.loadTasks()).map((task) => task.title), [
      'Buy Milk',
      'MILK the cow',
      'Read a book',
    ]);
  });

  testWidgets('sorts display order without changing saved tasks', (
    tester,
  ) async {
    final sortRepository = _EditableTaskRepository([
      const TaskItem(id: 'z', title: 'zebra', isCompleted: true),
      const TaskItem(id: 'b', title: 'Banana'),
      const TaskItem(id: 'a', title: 'apple'),
    ]);
    await tester.pumpWidget(MyApp(repository: sortRepository));
    await tester.pumpAndSettle();

    double top(String title) => tester.getTopLeft(find.text(title)).dy;

    expect(top('zebra'), lessThan(top('Banana')));
    expect(top('Banana'), lessThan(top('apple')));

    await _tapVisible(tester, find.text('По умолчанию'));
    await _tapVisible(tester, find.text('А–Я').last);
    expect(top('apple'), lessThan(top('Banana')));
    expect(top('Banana'), lessThan(top('zebra')));

    await _tapVisible(tester, find.text('А–Я').first);
    await _tapVisible(tester, find.text('Я–А').last);
    expect(top('zebra'), lessThan(top('Banana')));
    expect(top('Banana'), lessThan(top('apple')));

    await tester.enterText(find.bySemanticsIdentifier('task-search'), 'a');
    await _tapVisible(tester, find.text('Активные'));
    expect(find.text('zebra'), findsNothing);
    expect(top('Banana'), lessThan(top('apple')));
    expect(find.text('Незавершённых задач: 2'), findsOneWidget);
    expect((await sortRepository.loadTasks()).map((task) => task.title), [
      'zebra',
      'Banana',
      'apple',
    ]);
  });

  testWidgets('adds, completes, persists, and deletes tasks at narrow width', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    final input = find.bySemanticsIdentifier('task-input');
    await tester.enterText(input, 'First task');
    await tester.tap(find.bySemanticsIdentifier('add-task'));

    await tester.enterText(input, 'Second task');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_taskInputField).controller!.text, isEmpty);

    final tasks = await repository.loadTasks();
    expect(tasks, hasLength(2));
    expect(find.text('First task'), findsOneWidget);
    expect(find.text('Second task'), findsOneWidget);

    await tester.ensureVisible(
      find.bySemanticsIdentifier('complete-${tasks.first.id}'),
    );
    await tester.tap(find.bySemanticsIdentifier('complete-${tasks.first.id}'));
    await tester.pumpAndSettle();

    final updatedTasks = await repository.loadTasks();
    expect(updatedTasks.first.isCompleted, isTrue);
    expect(updatedTasks.last.isCompleted, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('First task'), findsOneWidget);
    expect(find.text('Second task'), findsOneWidget);

    final deleteButton = find.bySemanticsIdentifier('delete-${tasks.last.id}');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    final finalTasks = await repository.loadTasks();
    expect(finalTasks, hasLength(1));
    expect(finalTasks.single.id, tasks.first.id);
    expect(finalTasks.single.isCompleted, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('edits a title, rejects blanks, cancels, and persists status', (
    tester,
  ) async {
    final editRepository = _EditableTaskRepository([
      const TaskItem(id: 'edit-me', title: 'Current title', isCompleted: true),
    ]);
    await tester.pumpWidget(MyApp(repository: editRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.bySemanticsIdentifier('edit-edit-me'));
    await tester.tap(find.bySemanticsIdentifier('edit-edit-me'));
    await tester.pumpAndSettle();

    final editField = find.byType(TextField).last;
    expect(
      tester.widget<TextField>(editField).controller!.text,
      'Current title',
    );
    await tester.enterText(editField, '   ');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Сохранить'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Current title'), findsOneWidget);

    await tester.ensureVisible(find.bySemanticsIdentifier('edit-edit-me'));
    await tester.tap(find.bySemanticsIdentifier('edit-edit-me'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Renamed task');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect((await editRepository.loadTasks()).single.title, 'Renamed task');
    expect(find.text('Renamed task'), findsOneWidget);
    expect(find.text('Current title'), findsNothing);
    expect((await editRepository.loadTasks()).single.isCompleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MyApp(repository: editRepository));
    await tester.pumpAndSettle();
    expect(find.text('Renamed task'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('duplicates a task from the list without changing its source', (
    tester,
  ) async {
    final duplicateRepository = _EditableTaskRepository([
      const TaskItem(id: 'source', title: 'Duplicate me', isCompleted: true),
    ]);
    await tester.pumpWidget(MyApp(repository: duplicateRepository));
    await tester.pumpAndSettle();

    final duplicateButton = find.bySemanticsIdentifier('duplicate-source');
    await tester.ensureVisible(duplicateButton);
    await tester.tap(duplicateButton);
    await tester.pump();
    await tester.pumpAndSettle();

    final tasks = await duplicateRepository.loadTasks();
    expect(tasks, hasLength(2));
    expect(tasks.first.id, 'source');
    expect(tasks.first.title, 'Duplicate me');
    expect(tasks.first.isCompleted, isTrue);
    expect(tasks.last.id, isNot('source'));
    expect(tasks.last.title, 'Duplicate me');
    expect(tasks.last.isCompleted, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MyApp(repository: duplicateRepository));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate me'), findsNWidgets(2));
    expect(await duplicateRepository.loadTasks(), hasLength(2));
  });

  testWidgets('does not accept tasks until the saved list has loaded', (
    tester,
  ) async {
    final delayedRepository = _DelayedTaskRepository();
    await tester.pumpWidget(MyApp(repository: delayedRepository));

    expect(tester.widget<TextField>(_taskInputField).enabled, isFalse);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    delayedRepository.completeLoad([
      const TaskItem(id: 'saved', title: 'Saved before startup'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Saved before startup'), findsOneWidget);
    expect(tester.widget<TextField>(_taskInputField).enabled, isTrue);
  });

  testWidgets('shows retry after storage initialization fails', (tester) async {
    final retryingRepository = _RetryingTaskRepository();
    await tester.pumpWidget(MyApp(repository: retryingRepository));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить задачи'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Задач пока нет'), findsOneWidget);
    expect(retryingRepository.loadAttempts, 2);
  });

  testWidgets('keeps a rejected add retryable and hides the unsaved task', (
    tester,
  ) async {
    final flakyRepository = _FlakyTaskRepository();
    await tester.pumpWidget(MyApp(repository: flakyRepository));
    await tester.pumpAndSettle();

    final input = find.bySemanticsIdentifier('task-input');
    final addButton = find.bySemanticsIdentifier('add-task');
    await tester.enterText(input, 'Retry this task');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Не удалось сохранить задачи'), findsOneWidget);
    expect(
      tester.widget<TextField>(_taskInputField).controller!.text,
      'Retry this task',
    );
    expect(find.byType(Checkbox), findsNothing);
    expect(flakyRepository.tasks, isEmpty);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(flakyRepository.tasks.single.title, 'Retry this task');
    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.widget<TextField>(_taskInputField).controller!.text, isEmpty);
  });

  testWidgets('serializes writes when rapid actions overlap', (tester) async {
    final semantics = tester.ensureSemantics();
    final delayedRepository = _SerializedTaskRepository();
    await tester.pumpWidget(MyApp(repository: delayedRepository));
    await tester.pumpAndSettle();

    final input = find.bySemanticsIdentifier('task-input');
    await tester.enterText(input, 'First write');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pump();
    await delayedRepository.firstWriteStarted.future;

    await tester.enterText(input, 'Second write');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pump();
    expect(delayedRepository.startedTitles, ['First write']);

    delayedRepository.releaseFirstWrite.complete();
    await tester.pumpAndSettle();

    expect(delayedRepository.startedTitles, ['First write', 'Second write']);
    expect(delayedRepository.tasks.map((task) => task.title), [
      'First write',
      'Second write',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MyApp(repository: delayedRepository));
    await tester.pumpAndSettle();

    expect(find.text('First write'), findsOneWidget);
    expect(find.text('Second write'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('does not enqueue a draft twice while its save is pending', (
    tester,
  ) async {
    final delayedRepository = _SerializedTaskRepository();
    await tester.pumpWidget(MyApp(repository: delayedRepository));
    await tester.pumpAndSettle();

    final input = find.bySemanticsIdentifier('task-input');
    final addButton = find.bySemanticsIdentifier('add-task');
    await tester.enterText(input, 'First write');
    await tester.tap(addButton);
    await tester.pump();
    await delayedRepository.firstWriteStarted.future;

    await tester.tap(addButton);
    await tester.pump();
    delayedRepository.releaseFirstWrite.complete();
    await tester.pumpAndSettle();

    expect(delayedRepository.startedTitles, ['First write']);
    expect(delayedRepository.tasks, hasLength(1));
    expect(tester.widget<TextField>(_taskInputField).controller!.text, isEmpty);
  });

  testWidgets('keeps the form usable with a keyboard inset and short height', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final layoutRepository = _RecordingTaskRepository();
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(MyApp(repository: layoutRepository));
    await tester.pumpAndSettle();

    final input = find.bySemanticsIdentifier('task-input');
    final addButton = find.bySemanticsIdentifier('add-task');
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Short screen task');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(layoutRepository.addAttempts, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _EditableTaskRepository extends TaskRepository {
  _EditableTaskRepository(this.tasks);

  final List<TaskItem> tasks;

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<List<TaskItem>> renameTask(String taskId, String title) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    tasks[index] = TaskItem(
      id: taskId,
      title: title,
      isCompleted: tasks[index].isCompleted,
    );
    return List.of(tasks);
  }

  @override
  Future<List<TaskItem>> duplicateTask(String taskId) async {
    final source = tasks.firstWhere((task) => task.id == taskId);
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    while (tasks.any((task) => task.id == id)) {
      id = '$id-';
    }
    tasks.add(TaskItem(id: id, title: source.title));
    return List.of(tasks);
  }

  @override
  Future<List<TaskItem>> deleteCompletedTasks() async {
    tasks.removeWhere((task) => task.isCompleted);
    return List.of(tasks);
  }
}

class _FailingCompletedDeleteRepository extends _EditableTaskRepository {
  _FailingCompletedDeleteRepository(super.tasks);

  @override
  Future<List<TaskItem>> deleteCompletedTasks() {
    throw StateError('Storage is temporarily unavailable');
  }
}

class _DelayedTaskRepository extends TaskRepository {
  final _loadCompleter = Completer<List<TaskItem>>();

  void completeLoad(List<TaskItem> tasks) => _loadCompleter.complete(tasks);

  @override
  Future<List<TaskItem>> loadTasks() => _loadCompleter.future;
}

class _RetryingTaskRepository extends TaskRepository {
  var loadAttempts = 0;

  @override
  Future<List<TaskItem>> loadTasks() async {
    loadAttempts++;
    if (loadAttempts == 1) {
      throw StateError('Storage is temporarily unavailable');
    }
    return [];
  }
}

class _FlakyTaskRepository extends TaskRepository {
  final tasks = <TaskItem>[];
  var _shouldRejectNextAdd = true;

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<List<TaskItem>> addTask(TaskItem task) async {
    if (_shouldRejectNextAdd) {
      _shouldRejectNextAdd = false;
      throw StateError('Storage is temporarily unavailable');
    }
    tasks.add(task);
    return List.of(tasks);
  }
}

class _RecordingTaskRepository extends TaskRepository {
  var addAttempts = 0;
  final tasks = <TaskItem>[];

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<List<TaskItem>> addTask(TaskItem task) async {
    addAttempts++;
    tasks.add(task);
    return List.of(tasks);
  }
}

class _SerializedTaskRepository extends TaskRepository {
  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  final startedTitles = <String>[];
  final tasks = <TaskItem>[];

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<List<TaskItem>> addTask(TaskItem task) async {
    startedTitles.add(task.title);
    if (startedTitles.length == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    tasks.add(task);
    return List.of(tasks);
  }
}
