# Product design — lean Material-first workflow (V2)

Design a usable product, not a collection of widgets. The build parent owns
design and integration; use the same Luna planning/execution roles already
configured. No mandatory design agent, premium model, design approval or
additional review round. Apply proportionately.

## 1. Choose a design direction before UI code

For minor changes preserve the existing visual language and adapt the
relevant component; no new mockups. For a substantial new screen, major
navigation/flow or redesign, establish the behavior contract (BEHAVIOR.md)
first. Identify the primary job, focal content, frequent and rare actions,
required states and the space available. Inspect the actual existing screen
when changing it, if available, and relevant reference images. Prefer
existing product references, then relevant Material examples from the SDK
or official Material documentation (https://m3.material.io/). The local
references/content-priority.svg is a teaching illustration, not a required
layout or a runtime screenshot. Render/view an image rather than judging
its markup alone. If a reference or rendering tool is unavailable, state
the limitation; do not repeatedly hunt for tools or claim inspection.

For an explicit redesign, preserving functionality does NOT mean preserving
the old composition. First capture and actually inspect the existing populated
screen at a representative compact viewport if it can run. Use realistic,
non-sensitive fixture content, not an empty screen; retain existing data.
Identify the two or three most consequential baseline UX problems and their
observable impact. Save the baseline path and viewport in the design handoff;
if it cannot be captured, name the actual limitation once. Do not treat the
old layout as the default solution simply because it already compiles.

Before UI edits, record a compact design decision in the existing behavior
contract (one section, not another document). For a substantial redesign:
- State the primary job and rank content, frequent actions and rare actions.
- Sketch two materially different layout/interaction options with the same
  realistic content at a representative compact width; an annotated text
  wireframe is sufficient for this planning step. If visual tools are already
  available, a small rendered concept may help. Do not build two Flutter apps.
- Choose the layout, explain why it improves the baseline, and name specific
  changes to placement, persistent controls, secondary actions and density.
- Specify observable visual acceptance: the primary content start and visible
  useful items (where meaningful), long-label handling, selected state,
  action access, empty/error state and width/theme evidence. Use a target tied
  to actual content and viewport, not an arbitrary screen percentage.
- A retained control or layout with a baseline defect needs a user-job
  justification. Do not confuse unchanged functionality with unchanged UI.
For new screens, one coherent annotated layout is enough unless a real
structural trade-off needs comparison. No extra agent, approval or art contest.

Choose one coherent direction: layout and reading order, primary action,
secondary actions, navigation, content density, typography, surfaces,
responsive behavior and the meaningful state transitions. Keep a compact
handoff in the behavior contract or local task plan. A single focused revision if needed; no default separate SVG app,
duplicated UI implementation or design competition. Do not delay an
obvious standard Material solution for high-fidelity mockup production.
Planning wireframes are not evidence of runtime visual quality.

## 2. Design for the product's actual job

- Content first for content-oriented utilities. Use navigation, summaries,
  dashboards or prominent calls to action when the primary job warrants them,
  not because a generic design template includes them.
- Use a clear visual hierarchy, consistent grid and spacing rhythm, readable
  type, intentional contrast, semantic color roles and restrained accents.
  Avoid nested surfaces, redundant labels, gratuitous chips, heroes and
  invented metrics. Every element must have a job; minimalism must not hide
  frequent actions or important state.
- Use ordinary Material 3 patterns and existing theme tokens. Customize
  when a real product requirement warrants it. No second platform visual
  tree, pretend UIKit effects, or new UI kit for standard controls.
- Maintain predictable selected states, discoverability, visible feedback,
  recoverable errors and accessible explicit alternatives to gesture-only
  actions. Avoid custom animation when a standard component works.
- Use realistic data, including long labels, multiple statuses and values.
  Respect touch targets, text scale, focus, contrast, keyboard, safe areas
  and width. On wide screens choose a meaningful bounded layout or additional
  panes only when useful, not arbitrary empty columns.
- Do not invent fields, branding, product features, navigation or marketing
  content to fill a composition. Search, filters, sorting and other state
  must follow the behavior contract, not a static mockup.

Examples across product types:
- A task list prioritizes tasks and frequent actions; rare row actions can
  be contextual. Keep independent sort/group/filter state comprehensible.
- A finance history prioritizes descriptions, dates, amounts and scope.
  Align amounts for comparison; use signs/labels as well as color; never
  invent categories or balances. Search may deserve persistent space.
- A form prioritizes labels, valid input, recovery and the next action;
  distinguish required/optional fields and preserve input after failure.
  A dashboard prioritizes meaningful decisions, not maximum card count.
  These are examples, not fixed screen templates.

## 3. Implement and inspect

The parent communicates the selected direction, interaction rules and shared
tokens to each UI slice. Do not change the product contract to make a visual
implementation easier. Reuse stock controls and coherent feature components;
avoid independently invented styling per worker.

After integration, capture representative actual Flutter runtime screen(s)
for the changed flow, at the affected widths and themes per PRODUCT.md.
Use the installed CLI launch/capture on one explicit representative target; capture receipts are candidate-bound. For meaningful interaction, use a scripted scenario or inspect actual state before capturing. Prefer one stable
runtime session and targeted refresh over rebuilding every platform. If
isolated fixture data is needed, use the real screen and design system;
never ship demo data or erase real records. Static mockups, SVGs and Ahem
test renders cannot establish runtime visual acceptance.

For substantial redesigns capture a populated final screen and a key changed
interaction at the representative compact width, in both light and dark
on one runtime platform. Use comparable content/viewport to the baseline
where possible; inspect wide layout when affected. Save actual image paths
under .flutter-harness/previews/ and include them in the handoff and PR.
Do not count a build, an empty screen or an unopened file as visual review.

Compare actual captures against the intended design, baseline and request:
- **Hierarchy:** where does real content start; how many useful items are
  visible; is an avoidable stack of persistent controls still dominating?
  For a content-first utility, the list is the primary content, not its form.
  For other product types use the corresponding primary job, not list metrics.
- **Actions:** can users find frequent actions, and do rare actions consume
  space better used by content? Contextual means actually available in context,
  not a claim in a spec. Are destructive actions and scope clear?
- **State:** is the selected mode/order/filter readable without guessing?
  Does a label such as "Default" explain what it does? Does an icon-only
  action have an accessible label/tooltip?
- **Craft:** inspect alignment, spacing rhythm, hierarchy, readable long
  content, contrast, clipping, safe areas and representative themes.
- **Outcome:** what material UX problems did the redesign actually solve?
  A mere alignment/spacing tweak or green sorting tests are insufficient for
  a broad redesign if the dominant baseline issues remain. Preserve data,
  identity, behavior and important states, not unnecessary old layout.

Use behavioral tests for interactions and persistence; screenshots cannot
prove animation smoothness, keyboard behavior or accessibility compliance.
When an important gesture/animation is changed, inspect its actual behavior
with the smallest appropriate runtime check. Fix material defects and
inspect changed evidence, not endless aesthetic variations.

For changes requiring independent review, give the existing reviewer the
original request, behavior contract, chosen design and actual images.
It should identify concrete product or visual defects and their impact,
not reward a generic clean appearance or invent arbitrary preferences.
Require the same reviewer to open the supplied populated runtime images,
not infer quality from source, a build log or the parent's statement.
Review against the original job and the observable baseline/target, not
only against a self-authored design contract. Name evidence inspected,
one concrete finding per material defect and its user impact. If the
design direction is too conservative, challenge it. Visual acceptance is
separate from correctness; report VISUAL: PASS immediately before the final
VERDICT: PASS for a visual task. Otherwise report VISUAL: CHANGES_REQUIRED
and VERDICT: CHANGES_REQUIRED. A logic-only targeted recheck can reuse
unchanged images after actually inspecting them. Do not retake them for
invisible source changes. No extra design reviewer or numeric beauty score.
Required visual evidence missing means visual acceptance is BLOCKED; do not
substitute a mockup or green analyzer/test output. Report the specific gap.
The guard checks the explicit reviewer verdict, not aesthetic truth or the
provenance of an image; the owner still makes final aesthetic acceptance.
Respect existing bounded recovery and publication policy.
