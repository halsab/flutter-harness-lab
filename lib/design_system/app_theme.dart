import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF202B27);
  static const forest = Color(0xFF286653);
  static const canvas = Color(0xFFF5F7F4);
  static const line = Color(0xFFE4EAE5);
  static const muted = Color(0xFF78827C);
  static const mint = Color(0xFFE6F2EC);
  static const radius = 22.0;
  static const controlRadius = 16.0;
  static const heroRadius = 26.0;
  static const progressRadius = 8.0;
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 20.0;
  static const space2xl = 24.0;
  static const pageInset = 32.0;
  static const compactPageInset = 18.0;
  static const maxContentWidth = 920.0;
  static const compactBreakpoint = 420.0;
  static const emptyStateHeight = 200.0;
  static const emptyListHeight = 240.0;
  static const heroTitleSize = 32.0;
  static const taskRowPadding = 4.0;
  static const taskRowInset = 8.0;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: forest, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ink, height: 1.35),
        bodyMedium: TextStyle(color: muted, height: 1.4),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8BCDB0),
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF131916),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: const Color(0xFF1B231F),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF303B35)),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131916),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
