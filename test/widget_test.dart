import 'dart:async';
import 'dart:convert';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoSearchTextField;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:flutter_harness_lab/app/app.dart';
import 'package:flutter_harness_lab/design_system/design_system.dart';
import 'package:flutter_harness_lab/features/tasks/models/task_item.dart';
import 'package:flutter_harness_lab/features/tasks/repositories/task_repository.dart';
import 'package:flutter_harness_lab/features/tasks/view_models/task_list_model.dart';

Finder get _taskInputField => find.descendant(
  of: find.bySemanticsIdentifier('task-input'),
  matching: find.byType(TextField),
);

Finder get _add => find.bySemanticsIdentifier('add-task');
Finder get _search => find.bySemanticsIdentifier('task-search');

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _addTask(WidgetTester tester, String title) async {
  await _tap(tester, _add);
  await tester.enterText(_taskInputField, title);
  await tester.pump();
  await _tap(tester, find.text('Добавить'));
}

Future<void> _taskAction(WidgetTester tester, String id, String label) async {
  await _tap(tester, find.bySemanticsIdentifier('actions-$id'));
  await _tap(tester, find.text(label));
}

Future<void> _sort(WidgetTester tester, String label) async {
  await _tap(tester, find.byTooltip('Сортировка'));
  await _tap(tester, find.text(label));
}

Finder _scope(String label) => find.descendant(
  of: find.byWidgetPredicate((widget) => widget is SegmentedButton),
  matching: find.text(label),
);

void main() {
  late TaskRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    repository = TaskRepository(preferences: preferences);
  });

  Widget materialApp(TaskRepository repository) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    return App(repository: repository);
  }

  testWidgets('shows an empty state and rejects blank task titles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(materialApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Задач пока нет'), findsOneWidget);
    expect(find.text('Добавьте первую задачу'), findsOneWidget);
    expect(find.text('Осталось 0 задач'), findsOneWidget);

    await _tap(tester, find.text('Добавьте первую задачу'));
    final submit = find.widgetWithText(FilledButton, 'Добавить');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(_taskInputField, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await _tap(tester, find.text('Отмена'));
    expect(find.text('Задач пока нет'), findsOneWidget);
    expect(await repository.loadTasks(), isEmpty);
    semantics.dispose();
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
    await tester.pumpWidget(materialApp(filterRepository));
    await tester.pumpAndSettle();

    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Осталось 1 задача'), findsOneWidget);

    await tester.tap(_scope('Активные'));
    await tester.pumpAndSettle();
    expect(find.text('Active task'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);

    await tester.tap(_scope('Завершённые'));
    await tester.pumpAndSettle();
    expect(find.text('Active task'), findsNothing);
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Осталось 1 задача'), findsOneWidget);

    await tester.tap(_scope('Все'));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(materialApp(filterRepository));
    await tester.pumpAndSettle();

    await tester.tap(_scope('Активные'));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(materialApp(deleteRepository));
    await tester.pumpAndSettle();

    await tester.enterText(_search, 'Matching');
    await tester.pumpAndSettle();
    expect(find.text('Очистить'), findsNothing);
    await _tap(tester, _scope('Активные'));
    expect(find.text('Очистить'), findsNothing);
    await _tap(tester, find.text('Сбросить поиск'));
    expect(find.text('Keep this active task'), findsOneWidget);
    expect(find.text('Очистить'), findsNothing);
    await _tap(tester, _scope('Все'));
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить завершённые задачи?'), findsOneWidget);
    expect(find.textContaining('все завершённые задачи (2)'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(deleteRepository.tasks, hasLength(3));

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(deleteRepository.tasks.map((task) => task.id), ['active']);
    expect(find.text('Keep this active task'), findsOneWidget);
    expect(find.text('Matching completed task'), findsNothing);
    expect(find.text('Other completed task'), findsNothing);
    expect(find.text('Осталось 1 задача'), findsOneWidget);
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
    await tester.pumpWidget(materialApp(failedRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(materialApp(searchRepository));
    await tester.pumpAndSettle();

    final search = find.bySemanticsIdentifier('task-search');
    await tester.enterText(search, 'milk');
    await tester.pump();
    expect(find.text('Buy Milk'), findsOneWidget);
    expect(find.text('MILK the cow'), findsOneWidget);
    expect(find.text('Read a book'), findsNothing);
    expect(find.text('Осталось 2 задачи'), findsOneWidget);

    await tester.tap(_scope('Завершённые'));
    await tester.pumpAndSettle();
    expect(find.text('Buy Milk'), findsNothing);
    expect(find.text('MILK the cow'), findsOneWidget);
    expect(find.text('Осталось 2 задачи'), findsOneWidget);

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
    await tester.pumpWidget(materialApp(sortRepository));
    await tester.pumpAndSettle();

    double top(String title) => tester.getTopLeft(find.text(title)).dy;

    expect(top('Banana'), lessThan(top('apple')));
    expect(top('apple'), lessThan(top('zebra')));

    await _sort(tester, 'По названию: А–Я');
    expect(top('apple'), lessThan(top('Banana')));
    expect(top('Banana'), lessThan(top('zebra')));

    await _sort(tester, 'По названию: Я–А');
    expect(top('zebra'), lessThan(top('Banana')));
    expect(top('Banana'), lessThan(top('apple')));

    await tester.enterText(find.bySemanticsIdentifier('task-search'), 'a');
    await _tap(tester, _scope('Активные'));
    await tester.pumpAndSettle();
    expect(find.text('zebra'), findsNothing);
    expect(top('Banana'), lessThan(top('apple')));
    expect(find.text('Осталось 2 задачи'), findsOneWidget);
    await _tap(tester, _scope('Все'));
    await _sort(tester, 'По умолчанию');
    expect(top('apple'), lessThan(top('zebra')));
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

    await tester.pumpWidget(materialApp(repository));
    await tester.pumpAndSettle();

    await _addTask(tester, 'First task');
    await _addTask(tester, 'Second task');
    expect(_taskInputField, findsNothing);

    final tasks = await repository.loadTasks();
    expect(tasks, hasLength(2));
    expect(find.text('First task'), findsOneWidget);
    expect(find.text('Second task'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('complete-${tasks.first.id}'));
    await tester.pumpAndSettle();

    final updatedTasks = await repository.loadTasks();
    expect(updatedTasks.first.isCompleted, isTrue);
    expect(updatedTasks.last.isCompleted, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(materialApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('First task'), findsOneWidget);
    expect(find.text('Second task'), findsOneWidget);

    await _taskAction(tester, tasks.last.id, 'Удалить');
    expect(find.text('Удалить задачу?'), findsOneWidget);
    await _tap(tester, find.text('Отмена'));
    expect(await repository.loadTasks(), hasLength(2));
    await _taskAction(tester, tasks.last.id, 'Удалить');
    await _tap(tester, find.text('Удалить'));

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
    await tester.pumpWidget(materialApp(editRepository));
    await tester.pumpAndSettle();

    await _taskAction(tester, 'edit-me', 'Переименовать');

    final editField = _taskInputField;
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

    await _taskAction(tester, 'edit-me', 'Переименовать');
    await tester.enterText(editField, 'Renamed task');
    await tester.pump();
    await _tap(tester, find.text('Сохранить'));

    expect((await editRepository.loadTasks()).single.title, 'Renamed task');
    expect(find.text('Renamed task'), findsOneWidget);
    expect(find.text('Current title'), findsNothing);
    expect((await editRepository.loadTasks()).single.isCompleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(materialApp(editRepository));
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
    await tester.pumpWidget(materialApp(duplicateRepository));
    await tester.pumpAndSettle();

    await _tap(tester, _scope('Завершённые'));
    await _taskAction(tester, 'source', 'Дублировать');

    final tasks = await duplicateRepository.loadTasks();
    expect(tasks, hasLength(2));
    expect(tasks.first.id, 'source');
    expect(tasks.first.title, 'Duplicate me');
    expect(tasks.first.isCompleted, isTrue);
    expect(tasks.last.id, isNot('source'));
    expect(tasks.last.title, 'Duplicate me');
    expect(tasks.last.isCompleted, isFalse);
    expect(find.text('Duplicate me'), findsOneWidget);
    expect(find.text('Задача дублирована'), findsOneWidget);
    await _tap(tester, find.text('Показать задачу'));
    expect(find.text('Duplicate me'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(materialApp(duplicateRepository));
    await tester.pumpAndSettle();
    expect(find.text('Duplicate me'), findsNWidgets(2));
    expect(await duplicateRepository.loadTasks(), hasLength(2));
  });

  testWidgets('does not accept tasks until the saved list has loaded', (
    tester,
  ) async {
    final delayedRepository = _DelayedTaskRepository();
    await tester.pumpWidget(materialApp(delayedRepository));
    expect(
      tester.widget<AppIconButton>(find.byType(AppIconButton)).onPressed,
      isNull,
    );
    await tester.tap(_add, warnIfMissed: false);
    await tester.pump();
    expect(_taskInputField, findsNothing);

    delayedRepository.completeLoad([
      const TaskItem(id: 'saved', title: 'Saved before startup'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Saved before startup'), findsOneWidget);
    await _tap(tester, _add);
    expect(tester.widget<TextField>(_taskInputField).enabled, isTrue);
  });

  testWidgets('shows retry after storage initialization fails', (tester) async {
    final retryingRepository = _RetryingTaskRepository();
    await tester.pumpWidget(materialApp(retryingRepository));
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
    const original = TaskItem(
      id: 'original',
      title: 'Saved task',
      isCompleted: true,
    );
    await repository.saveTasks([original]);
    final store = _ToggleWriteStore(jsonEncode([original.toJson()]));
    SharedPreferencesStorePlatform.instance = store;
    await tester.pumpWidget(materialApp(repository));
    await tester.pumpAndSettle();

    await _tap(tester, _scope('Завершённые'));
    await _tap(tester, _add);
    await tester.enterText(_taskInputField, 'Retry this task');
    await tester.pump();
    await tester.tap(find.text('Добавить'));
    await tester.pump();
    await tester.pump();
    final failure = find.text('Не удалось сохранить задачи');

    expect(store.rejectedWrites, 1);
    expect(failure, findsOneWidget);
    expect(
      tester.widget<TextField>(_taskInputField).controller!.text,
      'Retry this task',
    );
    expect(
      find.bySemanticsIdentifier('complete-original', skipOffstage: false),
      findsOneWidget,
    );
    expect((await repository.loadTasks()).map((task) => task.id), ['original']);

    store.reject = false;
    await _tap(tester, find.text('Добавить'));

    expect((await repository.loadTasks()).map((task) => task.title), [
      'Saved task',
      'Retry this task',
    ]);
    expect(_taskInputField, findsNothing);
    expect(find.text('Retry this task'), findsNothing);
    expect(find.text('Задача добавлена'), findsOneWidget);
    await _tap(tester, find.text('Показать задачу'));
    expect(find.text('Retry this task'), findsOneWidget);
  });

  test('serializes writes when rapid actions overlap', () async {
    final delayedRepository = _SerializedTaskRepository();
    final model = TaskListModel(delayedRepository);
    addTearDown(model.dispose);
    await model.load();

    final first = model.add('First write');
    await delayedRepository.firstWriteStarted.future;

    final second = model.add('Second write');
    await Future<void>.delayed(Duration.zero);
    expect(delayedRepository.startedTitles, ['First write']);

    delayedRepository.releaseFirstWrite.complete();
    expect(await Future.wait([first, second]), everyElement(isNotNull));

    expect(delayedRepository.startedTitles, ['First write', 'Second write']);
    final reloaded = TaskListModel(delayedRepository);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.view.tasks.map((task) => task.title), [
      'First write',
      'Second write',
    ]);
  });

  testWidgets('does not enqueue a draft twice while its save is pending', (
    tester,
  ) async {
    final delayedRepository = _SerializedTaskRepository();
    await tester.pumpWidget(materialApp(delayedRepository));
    await tester.pumpAndSettle();

    await _tap(tester, _add);
    await tester.enterText(_taskInputField, 'First write');
    await tester.pump();
    final submit = find.widgetWithText(FilledButton, 'Добавить');
    await tester.tap(submit);
    await tester.pump();
    await delayedRepository.firstWriteStarted.future;

    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();
    delayedRepository.releaseFirstWrite.complete();
    await tester.pumpAndSettle();

    expect(delayedRepository.startedTitles, ['First write']);
    expect(delayedRepository.tasks, hasLength(1));
    await _tap(tester, _add);
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

    await tester.pumpWidget(materialApp(layoutRepository));
    await tester.pumpAndSettle();

    await _addTask(tester, 'Short screen task');

    expect(layoutRepository.addAttempts, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('iOS pull discloses search without losing a focused query', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await repository.saveTasks([
      const TaskItem(id: 'other', title: 'Other task'),
      for (var i = 0; i < 20; i++)
        TaskItem(id: '$i', title: 'Matching task $i'),
    ]);
    await tester.pumpWidget(App(repository: repository));
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('task-list'));
    final search = find.byType(CupertinoSearchTextField);
    expect(search, findsNothing);
    final completion = tester
        .getSemantics(find.bySemanticsIdentifier('complete-other'))
        .getSemanticsData();
    expect(completion.flagsCollection.isEnabled, Tristate.isTrue);
    expect(completion.hasAction(SemanticsAction.tap), isTrue);

    await tester.drag(list, const Offset(0, 110));
    await tester.pumpAndSettle();
    expect(search, findsOneWidget);
    await tester.drag(list, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(search, findsNothing);

    await _tap(tester, find.bySemanticsLabel('Открыть поиск'));
    expect(search, findsOneWidget);
    await tester.enterText(search, 'Matching');
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoSearchTextField>(search).controller!.text,
      'Matching',
    );
    expect(find.text('Other task'), findsNothing);
    await _tap(tester, find.bySemanticsLabel('Очистить поиск'));
    expect(
      tester.widget<CupertinoSearchTextField>(search).controller!.text,
      isEmpty,
    );
    expect(find.text('Other task'), findsOneWidget);
    await tester.enterText(search, 'Matching');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Отмена'));
    expect(search, findsNothing);
    expect(find.text('Other task'), findsOneWidget);
  });

  testWidgets('narrow screen with large text keeps the scope menu usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await repository.saveTasks([
      const TaskItem(
        id: 'long',
        title: 'Подготовить документы для поездки и проверить срок действия',
      ),
      const TaskItem(
        id: 'completed',
        title: 'Оплатить интернет',
        isCompleted: true,
      ),
    ]);
    await tester.pumpWidget(materialApp(repository));
    await tester.pumpAndSettle();

    await _tap(tester, find.byTooltip('Статус: Все'));
    await _tap(tester, find.text('Завершённые').last);
    expect(find.text('Оплатить интернет'), findsOneWidget);
    expect(find.textContaining('Подготовить документы'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('follows live system appearance on ${platform.name}', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(App(repository: repository));
      await tester.pumpAndSettle();
      final body = find.byType(AppStateMessage);
      expect(
        usesCupertino(tester.element(body)),
        platform == TargetPlatform.iOS,
      );
      final light = AppColors.background(tester.element(body));

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      final dark = AppColors.background(tester.element(body));
      expect(dark.computeLuminance(), lessThan(light.computeLuminance()));
    });
  }
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

class _ToggleWriteStore extends InMemorySharedPreferencesStore {
  _ToggleWriteStore(String data) : super.withData({'flutter.my_tasks': data});

  bool reject = true;
  var rejectedWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (!reject) return super.setValue(valueType, key, value);
    rejectedWrites++;
    return Future.value(false);
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
