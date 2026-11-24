import 'package:flutter/widgets.dart';

import '../design_system/design_system.dart';
import '../features/tasks/repositories/task_repository.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/view_models/task_list_view_model.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository});

  final TaskRepository? repository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _model = TaskListViewModel(widget.repository ?? TaskRepository());

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppRoot(
    title: 'Мои задачи',
    home: TaskListScreen(viewModel: _model),
  );
}
