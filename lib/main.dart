import 'package:material_ui/material_ui.dart';

import 'data/task_repository.dart';
import 'features/tasks/task_list_screen.dart';

export 'features/tasks/task_list_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final TaskRepository? repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Мои задачи',
    theme: ThemeData(
      colorScheme: .fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    ),
    home: TaskListScreen(repository: repository),
  );
}
