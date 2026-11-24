# Product foundation — project defaults

One shared Flutter codebase on Android, iOS and Flutter Web. No React or
second web stack. These are defaults, not decisions to re-litigate for
every product. A user's explicit product requirement overrides a visual
choice; document genuine architectural exceptions rather than bypass checks.

## Architecture (feature-first MVVM)

- main.dart: only imports app/bootstrap.dart and calls bootstrap().
- app/: composition root, DI via constructors, app shell, routing and l10n.
- features/<feature>/{models,repositories,services,view_models,screens,widgets,use_cases}/:
  create only layers needed. Models and pure transformations are independent.
  Repositories own persistent/network data and mutations; services wrap external
  APIs. ViewModels own feature state, validation, actions, loading/error and
  presentation derivation. Use ChangeNotifier from flutter/foundation.dart
  and ListenableBuilder; dispose ownership correctly. Screens/widgets render
  state and forward intent, own only ephemeral UI controllers/focus/animation.
  Use cases are optional for complex multi-repository business rules.
- core/: genuinely shared non-product infrastructure/contracts. No dependency
  on features or app. Avoid generic utils dumping ground and empty layers.
- design_system/: tokens, themes, reusable controls, accessibility and layout
  patterns; no feature dependencies.
- Tests mirror meaningful logic. Inject fakes at repository/service boundaries.
  Preserve real persistence tests; every new material write operation considers
  rejected-write and reload behavior before the first review.
- No global service locator, blanket interfaces, code generation, new state
  manager or router just to satisfy the folder tree. Use Navigator by default,
  go_router when actual deep links/nested routes warrant it.
- Other defaults when needed: one HTTP client, shared_preferences for small
  non-secret preferences, durable structured storage for substantive data,
  secure storage for secrets, Flutter l10n for localization. Select dependencies
  only for an actual requirement; do not install a speculative stack.
- Independent features must not import each other's internals. Compose them
  in app, or extract a shared contract/model to core if warranted.

## UX — design the flow, not a pile of controls

For a new screen or meaningful UX change, privately identify primary user
intent, information hierarchy, most frequent action, and secondary actions.
Start with the content. Keep primary action easy to reach; progressive
disclosure for search, sort, filters and overflow actions when less frequent.
Keep common actions discoverable, not gesture-only. Use consistent navigation,
back behavior, form validation, focus, feedback, and destructive confirmation
or undo according to consequence. Treat loading, empty, filtered-empty,
error, saving and success states as intentional parts of the flow. Preserve
behavior, accessibility, data and all user requirements during redesign.
Do not vertically center a growing list/form as a group; top-align within
safe areas and let the content scroll naturally.

Use actual available width, not device model. Compact <600, medium 600–839,
expanded >=840 logical px are starting breakpoints. Respect text scaling,
safe areas, keyboard inset, touch targets (44 iOS / 48 Material logical px),
contrast, semantics, keyboard/focus/hover for Web, RTL and long translations.
Use platform-native navigation and controls where it matters, not a second
feature implementation. A single column is fine for a small app on desktop.

## UI profiles and design system

Default adaptive: official Material on Android/Web/other platforms; official
Cupertino on native iOS. Web stays Material even in Safari on iOS. Platform
widgets simulate platform design in Flutter; they are not actual native UIKit.
Universal: Material everywhere. Minimal: optional one verified Flutter
shadcn-style library; no dependency installed until selected and compatibility,
license, accessibility and SDK are checked. Custom: explicit project
references/brand or bespoke visual direction, still uses tokens/components.
Never silently mix visual systems in a screen. Adaptive and Universal have
a reusable starter; Minimal and Custom are extension contracts, not supplied
full component kits.

Use semantic colors, text styles, spacing, radii, layout widths, motion and
themes from design_system, with light/dark theme and system font defaults.
Default color policy: follow system light/dark appearance on all platforms
(including Flutter Web); no separate theme-settings screen unless requested.
Material 3 generates both ColorSchemes from Ocean Blue (#2563EB), a seed,
not a fixed foreground, button or background color. Native iOS Cupertino
uses CupertinoColors.systemBlue as its dynamic accent and platform semantic
colors for background, surfaces, label, secondary label, errors and separators.
Do not feed the Material seed into Cupertino. Resolve dynamic colors with
the active BuildContext. Use AppColors and AppTextStyles in feature code;
never freeze resolved colors in static fields or replace them with hand-picked
light/dark HEX tables. Keep native contrast pairs and component states.
No palette-selection question for routine new projects. Explicit brand or
visual requirements can override the seed or platform theme centrally in
design_system; preserve light/dark behavior. Cover system theme changes on
both platform implementations in shared starter widget tests.
Reuse existing controls/patterns before inventing new ones. Feature-specific
widgets stay in feature, repeated generic patterns belong in design_system.
Use neutral Flutter layout widgets directly; wrap a control only for real
consistency or platform abstraction, not every SDK widget. Do not hard-code
palette/typography/spacing or import platform-specific design libraries in
feature screens. Keep one implementation of the feature behavior.
The official Material/Cupertino packages for the pinned SDK are the first
choice. Check project SDK and pubspec before changing dependencies.

## Visual acceptance and review

For a material new screen, redesign, major navigation/flow or design-system
change, inspect actual rendered screenshots of the changed screen(s), with
representative content and the key changed state. For adaptive initial
adoption inspect both iOS Cupertino and Android or Flutter Web Material;
inspect light and dark appearance of both variants at initial adoption.
For an isolated later change inspect only the affected visual variants and
themes; for palette or theme changes include both light and dark.
Check narrow/large layouts and large text using fast widget assertions where
meaningful, plus a representative desktop width if Web layout changes.
Use actual local simulator/browser captures, not mockups or Ahem widget-test
screenshots as proof of polished visual design. Save local previews under
.flutter-harness/previews/ (ignored); include exact paths/viewport/platform
in reviewer handoff and PR, attach screenshots when supported.
Review hierarchy, spacing, discoverability, clipping, theme, states,
platform conventions and reuse. One read-only reviewer covers correctness,
architecture and UX, not three separate agents. If runtime visual review is
unavailable, say BLOCKED for required visual acceptance, do not claim PASS.
A screenshot is semantic review evidence, not an executable functional test.
No routine visual/E2E checks for non-visual changes, no golden auto-approval.
Owner makes final aesthetic acceptance.

## Adoption and checks

Installer copies this policy, product.json and starter templates without
overwriting app source or installing dependencies. Pending adoption means
the project needs a first implementation/migration; ordinary local checks
fail until product foundation is activated. On a fresh app or explicit
migration, copy/adapt the starter and composition-root skeleton with `python3 .flutter-harness/bin/init-product.py .`,
choose only needed components, move code and tests to the specified structure,
wire AppRoot and feature ViewModels, and change product.json status to active.
Do not mark active before actual integration. Pending is permitted in CI only
for initial configuration-only adoption (no application changes), not a bypass
after activation. The checker is a lightweight convention/import/token check,
not a complete Dart semantic or aesthetic verifier. Analyzer and actual review
are still required. Do not disable checks or move violations into arbitrary
allowed directories. Use a separately reviewed product-foundation update if
a justified exception is required.

## Efficient delivery

Identify meaningful failure scenarios before editing. For failed targeted
tests, fix the specific cause rather than rerun the whole suite; after two
unsuccessful attempts at the same substantive failure, consult Sol architect
once for a focused diagnosis and implement its recommendation. Ordinary format
failures do not need escalation. A difficult architectural decision gets one
Sol consultation before implementation; established baseline choices do not.
Use one final standard check after implementation/review corrections. If
independent review is required, it may run concurrently with deterministic
checks on the unchanged candidate. Wait for review result without duplicate
review requests or unrelated edits. Fix material findings, run affected
targeted checks and one final standard run if the candidate changed, then
one targeted re-review at most. No additional review loops or mandatory E2E.
