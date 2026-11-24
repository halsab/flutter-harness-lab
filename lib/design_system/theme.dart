import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import 'app_root.dart';

/// Semantic roles resolve with the active theme, including dark mode.
abstract final class AppColors {
  static Color _resolve(BuildContext context, Color color) =>
      c.CupertinoDynamicColor.resolve(color, context);

  static Color primary(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoTheme.of(context).primaryColor)
      : m.Theme.of(context).colorScheme.primary;

  static Color background(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoColors.systemGroupedBackground)
      : m.Theme.of(context).colorScheme.surface;

  static Color surface(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoColors.secondarySystemGroupedBackground)
      : m.Theme.of(context).colorScheme.surfaceContainerLow;

  static Color text(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoColors.label)
      : m.Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) => usesCupertino(context)
      ? Color.alphaBlend(
          _resolve(context, c.CupertinoColors.label).withValues(alpha: 0.32),
          _resolve(context, c.CupertinoColors.secondaryLabel),
        )
      : m.Theme.of(context).colorScheme.onSurfaceVariant;

  static Color error(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoColors.systemRed)
      : m.Theme.of(context).colorScheme.error;

  static Color divider(BuildContext context) => usesCupertino(context)
      ? _resolve(context, c.CupertinoColors.systemGroupedBackground)
      : m.Theme.of(context).colorScheme.outlineVariant;
}

abstract final class AppTextStyles {
  static TextStyle body(BuildContext context) => usesCupertino(context)
      ? c.CupertinoTheme.of(context).textTheme.textStyle
            .copyWith(color: AppColors.text(context))
      : m.Theme.of(context).textTheme.bodyMedium ??
            DefaultTextStyle.of(context).style;

  static TextStyle heading(BuildContext context) => usesCupertino(context)
      ? body(context).copyWith(fontSize: 22, fontWeight: FontWeight.w600)
      : m.Theme.of(context).textTheme.titleLarge ??
            DefaultTextStyle.of(context).style;

  static TextStyle caption(BuildContext context) =>
      (usesCupertino(context)
              ? body(context).copyWith(fontSize: 13)
              : m.Theme.of(context).textTheme.bodySmall ?? body(context))
          .copyWith(color: AppColors.muted(context));

  static TextStyle pageTitle(BuildContext context) => usesCupertino(context)
      ? c.CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle
      : m.Theme.of(context).textTheme.headlineMedium ?? heading(context);

  static TextStyle section(BuildContext context) => body(context).copyWith(
    fontSize: usesCupertino(context) ? 15 : null,
    fontWeight: FontWeight.w600,
  );

  static TextStyle listBody(BuildContext context) => usesCupertino(context)
      ? body(context)
      : m.Theme.of(context).textTheme.bodyLarge ?? body(context);
}
