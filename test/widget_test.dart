import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_harness_lab/data/task_repository.dart';
import 'package:flutter_harness_lab/main.dart';

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

  testWidgets('adds, completes, persists, and deletes tasks at narrow width', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(repository: repository));

    final input = find.bySemanticsIdentifier('task-input');
    await tester.enterText(input, 'First task');
    await tester.tap(find.bySemanticsIdentifier('add-task'));

    await tester.enterText(input, 'Second task');
    await tester.tap(find.bySemanticsIdentifier('add-task'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

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
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('First task'), findsOneWidget);
    expect(find.text('Second task'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('delete-${tasks.last.id}'));
    await tester.pumpAndSettle();

    final finalTasks = await repository.loadTasks();
    expect(finalTasks, hasLength(1));
    expect(finalTasks.single.id, tasks.first.id);
    expect(finalTasks.single.isCompleted, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
