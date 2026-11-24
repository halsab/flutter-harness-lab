Reusable, deliberately small Adaptive/Universal Flutter design system starter.
Run init-product.py on the target project; it copies only missing files into
lib/design_system and a minimal app/bootstrap skeleton (existing main.dart is
preserved; replace the SDK entrypoint explicitly when adopting). For Flutter 3.50 use official material_ui and cupertino_ui
(verify versions against the project's SDK, e.g. material_ui ^1.1.0 and
cupertino_ui ^1.1.7). Add only missing dependencies with flutter pub add.
Wire AppRoot in lib/app/app.dart; select AppUiProfile.adaptive or universal.
For Russian or other locales pass the locale, supportedLocales and localization
delegates from the SDK and project l10n; install flutter_localizations as an
SDK dependency if needed. AppPage is a top-aligned shell; supply scrollable
content and appropriate layout per screen. AppButton, AppTextField, AppSwitch,
AppProgress, AppStateMessage, semantic AppColors/AppTextStyles and confirmAction are a starting set, not a full design library.
Extend centrally for menus, lists, search, empty/error, focus and responsive
patterns only when used. Use native platform text/theme colors from the
design-system layer; no feature-specific style literals. Keep one shared
business behavior. Minimal/Custom are optional project-specific implementations;
do not claim they are prebuilt. No source replacement or pub get at install.

Default appearance: Material 3 derives light/dark ColorSchemes from the
Ocean Blue seed (#2563EB); Cupertino uses systemBlue and dynamic system
roles. Both follow system brightness. Change the seed or platform theme
centrally only for explicit product branding. No custom HEX palette or
in-app theme picker is required by default. Starter smoke tests switch
system brightness in a live widget tree on both platforms.
