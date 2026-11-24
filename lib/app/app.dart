import 'package:flutter/widgets.dart';

import '../features/tasks/repositories/task_repository.dart';
import '../design_system/design_system.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/view_models/task_list_model.dart';

class App extends StatefulWidget {
  const App({super.key, this.repository});

  final TaskRepository? repository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _model = TaskListModel(widget.repository ?? TaskRepository());

  @override
  void initState() {
    super.initState();
    _model.load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppRoot(
    title: 'Мои задачи',
    supportedLocales: const [Locale('ru')],
    home: TaskListScreen(model: _model),
  );
}
