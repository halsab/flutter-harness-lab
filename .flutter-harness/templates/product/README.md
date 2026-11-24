Reusable, deliberately small Material 3 design-system starter for Android,
iOS and Flutter Web. Run init-product.py on the target project; it copies
only missing files into lib/design_system and the app/bootstrap skeleton.
Existing main.dart is preserved; wire it explicitly when adopting.

For Flutter 3.50 use the project's SDK-compatible material_ui package
(e.g. ^1.1.0); add it only when missing. No cupertino_ui dependency is
required. Wire AppRoot in lib/app/app.dart. Pass locale, supportedLocales
and localization delegates from the SDK/project l10n if needed.
AppPage is a top-aligned shell; use scrollable content and appropriate
layout per screen. Use stock Material controls directly in presentation
and reuse semantic AppColors/AppTextStyles, tokens and shared patterns.
Existing starter helper APIs are convenience widgets, not required
wrappers for every control. Extend only when there is an actual need.

Material 3 derives light/dark ColorSchemes from Ocean Blue (#2563EB).
System brightness and platform interaction behavior remain in effect.
Change branding centrally only on request. Starter smoke tests exercise
Material and system appearance on both Android and iOS target platforms.
New product.json uses universal; explicit custom styling is Material-based.
Legacy adaptive/minimal projects require a separate reviewed migration.
The installer preserves existing project source, policies and config.
