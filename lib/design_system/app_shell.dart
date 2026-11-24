import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({
    super.key,
    required this.title,
    required this.theme,
    required this.darkTheme,
    required this.home,
  });

  final String title;
  final ThemeData theme;
  final ThemeData darkTheme;
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    debugShowCheckedModeBanner: false,
    theme: theme,
    darkTheme: darkTheme,
    themeMode: ThemeMode.system,
    builder: (context, child) {
      final materialTheme = Theme.of(context);
      return CupertinoTheme(
        data: CupertinoThemeData(
          brightness: materialTheme.brightness,
          primaryColor: materialTheme.colorScheme.primary,
        ),
        child: child!,
      );
    },
    home: home,
  );
}
