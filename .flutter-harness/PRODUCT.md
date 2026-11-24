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

## Product behavior before visual design

For material new/changed behavior use the behavior contract guide
(BEHAVIOR.md in the reusable product template, installed at
.flutter-harness/templates/product/BEHAVIOR.md). Resolve intent, state,
combinations with existing features, failure paths and observable acceptance
examples before code or visual concepts. Update one existing feature spec or
docs/product/<feature>.md when warranted; no new document for trivial work.
Independent controls remain independent unless the user job justifies an
explicit dependency. Check the rules against the original request, not just
implementation/test agreement. No extra approval or premium model by default.

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
safe areas, keyboard inset, touch targets (48 Material logical px),
contrast, semantics, keyboard/focus/hover for Web, RTL and long translations.
Use familiar Material navigation and controls with normal platform behavior,
not a second visual implementation. A single column is fine for a small app on desktop.

## One visual foundation: Material 3

Use Material 3 on Android, iOS and Flutter Web (ui_profile: universal).
Do not implement a second Cupertino visual tree, introduce platform-specific
UI wrappers, or imitate UIKit interactions just because the device is iOS.
Keep Flutter's normal platform behavior (navigation, text editing, keyboard,
scroll physics, accessibility) and adapt layout to width and input method.
Use stock Material controls and interactions first; custom visual direction
builds on Material and the same design system (ui_profile: custom, when
explicitly requested). No optional second component kit by default.
Existing adaptive/minimal profile values are legacy compatibility only; do
not select them for new projects. Convert existing projects in a separate
reviewed migration rather than changing their setting behind the user's back.

One semantic light/dark theme follows system appearance on every platform.
Material 3 generates both ColorSchemes from Ocean Blue (#2563EB), a seed,
not a literal foreground, button or background color. Resolve theme roles
with the active BuildContext; don't freeze resolved colors or hand-build
parallel palettes. Explicit branding may change the seed/theme centrally.
No theme picker or palette question by default.

Use stock Material widgets directly in app/presentation with shared theme
and tokens. Keep palette, spacing, typography, radii and genuinely reusable
patterns in design_system. Feature-specific UI stays in its feature. Do not
wrap each SDK widget merely to hide its import, or add platform switches.
No direct UI imports in domain/data/ViewModels; no storage access in views.
Use the Material package compatible with the pinned SDK and existing project.
No new UI library dependency merely for styling. Preserve keyboard/focus,
safe areas, responsive layout, semantics, and large-text support.

## Visual design before implementation

For a substantial new screen, flow or redesign follow the compact DESIGN.md
guide in .flutter-harness/templates/product/. Define the behavior first;
choose a visual direction using relevant actual reference images and Material
patterns before delegating or coding UI. For explicit redesigns inspect the
populated baseline if available, compare two concise structural wireframes,
and record the chosen direction, baseline defects and observable visual
acceptance in the existing behavior contract. Preserve functionality, not
an ineffective composition. Keep the selected direction and interaction
notes in the task handoff. No mandatory mockup for ordinary UI
changes, no separate design-review agent, no premium model for visual design.

## Visual acceptance and review

For a material new screen, redesign, major navigation/flow or design-system
change, inspect actual rendered screenshots of the changed screen(s), with
representative content and the key changed state. For initial Material adoption
or a shared theme change inspect light and dark on one representative runtime platform. Inspect another platform only for an
actual platform-specific change or risk; inspect wide layout when affected.
For substantial redesigns inspect the populated final screen and key changed
interaction at a representative compact width in both themes; compare the
baseline at comparable content and width if available. A single screenshot
of an empty screen or a successful launch is insufficient. For isolated
changes inspect only affected states and representative widths.
Check narrow/large layouts and large text using fast widget assertions where
meaningful, plus a representative desktop width if Web layout changes.
Use actual local simulator/browser captures, not mockups or Ahem widget-test
screenshots as proof of polished visual design. Save local previews under
.flutter-harness/previews/ (ignored); include exact paths/viewport/platform
in reviewer handoff and PR, attach screenshots when supported.
Compare the actual rendered result with the selected direction, original
request and behavior contract. Review hierarchy, spacing, discoverability, clipping, theme, states,
platform behavior and reuse. Material hierarchy or interaction defects are
not cosmetic preferences. One read-only reviewer covers correctness,
architecture and UX, not three separate agents. If runtime visual review is
unavailable, say BLOCKED for required visual acceptance, do not claim PASS.
A screenshot is semantic review evidence, not an executable functional test.
No routine visual/E2E checks for non-visual changes, no golden auto-approval.
For material visual tasks the same reviewer reports an explicit VISUAL: PASS
before VERDICT: PASS only after opening actual runtime images and comparing
them to the user job and baseline/target. Owner makes final aesthetic acceptance.

## Adoption and checks

Installer copies this policy, product.json and starter templates without
overwriting app source or installing dependencies. Pending adoption means
the project needs a first implementation/migration; ordinary local checks
fail until product foundation is activated. On a fresh app or explicit
migration, copy/adapt the starter and composition-root skeleton with `python3 .flutter-harness/bin/init-product.py .`,
choose only needed components, move code and tests to the specified structure,
wire AppRoot and feature ViewModels, and change product.json status to active.
For an existing app with pending foundation, separate adoption from a broad
redesign or unrelated feature. An old installed policy is not automatically
updated by the installer; use a reviewed configuration sync first.
Do not mark active before actual integration. Pending is permitted in CI only
for initial configuration-only adoption (no application changes), not a bypass
after activation. The checker is a lightweight convention/import/token check,
not a complete Dart semantic or aesthetic verifier. Analyzer and actual review
are still required. Do not disable checks or move violations into arbitrary
allowed directories. Use a separately reviewed product-foundation update if
a justified exception is required.

## Efficient delivery

For broad or genuinely interacting changes use the installed ORCHESTRATION.md
guide. One High-effort Luna architect plans across product and implementation
boundaries; the Medium parent executes or delegates small stable-contract slices
to Low-effort workers. Do not require a planner or worker for simple changes.

Identify meaningful failure scenarios before editing. For failed targeted
tests, fix the specific cause rather than rerun the whole suite; after two
unsuccessful attempts at the same substantive failure, isolate the failing
case and, if useful, consult the Luna High architect once for focused
diagnosis. Apply the recommendation and check the affected behavior.
Ordinary format failures do not need escalation. Failed checks are work to
fix, not an external blocker. If bounded recovery fails, report INCOMPLETE.
The only standing premium-model exception is one focused Sol Medium advisor
consultation per original task under ORCHESTRATION.md. No premium build,
whole-project planning/review or automatic failure-based escalation. Other
premium use requires explicit user permission.
Use one final standard check after implementation/review corrections.
Reuse observed successful checks and review on unchanged source/tests/spec;
no duplicate full runs solely because the session resumed. Follow the
resource-aware recovery policy in ORCHESTRATION.md. If
independent review is required, it may run concurrently with deterministic
checks on the unchanged candidate. Wait for review result without duplicate
review requests or unrelated edits. Fix material findings, run affected
targeted checks and one final standard run if the candidate changed, then
one targeted re-review at most. No additional review loops or mandatory E2E.
