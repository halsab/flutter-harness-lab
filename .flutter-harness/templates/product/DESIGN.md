# Product design — lean Material-first workflow

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

Choose one coherent direction: layout and reading order, primary action,
secondary actions, navigation, content density, typography, surfaces,
responsive behavior and the meaningful state transitions. Keep a compact
handoff in the behavior contract or local task plan. If there is a real
layout trade-off (not just a different radius or color), compare two small
visual alternatives using the same content and constraints. Render actual
concept images when doing a visual comparison. Select one, explain the
trade-off in a few sentences. A single focused revision if needed; no
default separate SVG app, duplicated UI implementation or design competition.
Do not delay an obvious standard Material solution for mockup production.

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
Use existing local simulator/browser and preview tooling. Prefer one stable
runtime session and targeted refresh over rebuilding every platform. If
isolated fixture data is needed, use the real screen and design system;
never ship demo data or erase real records. Static mockups, SVGs and Ahem
test renders cannot establish runtime visual acceptance.

Compare actual captures against the intended design and request:
- Does the primary content have appropriate prominence and usable density?
- Are important actions and selected states discoverable and unambiguous?
- Do spacing, alignment, typography, contrast and surfaces feel coherent?
- Are long content, relevant empty/error states and changed layout handled?
- Has any functionality, identity, data or state rule changed unintentionally?

Use behavioral tests for interactions and persistence; screenshots cannot
prove animation smoothness, keyboard behavior or accessibility compliance.
When an important gesture/animation is changed, inspect its actual behavior
with the smallest appropriate runtime check. Fix material defects and
inspect changed evidence, not endless aesthetic variations.

For changes requiring independent review, give the existing reviewer the
original request, behavior contract, chosen design and actual images.
It should identify concrete product or visual defects and their impact,
not reward a generic clean appearance or invent arbitrary preferences.
No extra design reviewer or numeric beauty score. Required visual evidence
missing means visual acceptance is BLOCKED; do not substitute a mockup
or green analyzer/test output. Report the specific gap. Respect the existing
bounded recovery and publication policy.
