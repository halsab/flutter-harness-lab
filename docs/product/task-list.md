# Task list contract

## Intent and design

Keep the task list as the main content; retain the existing add, complete,
rename, duplicate, delete, bulk-delete, filter, search, sort and persistence
behavior without changing stored records or their order.

The populated iOS baseline (`.flutter-harness/previews/189fd3e2fcbcfcf31e4b064b0ea1a557ffd5d2b235ef8a5bd20e0fe2d36d2fd5/baseline-ios-light.png`,
390 logical px wide) has oversized stacked input/filter/sort controls ahead
of the list, persistent row action icons consuming space, and a lone record
that does not communicate list hierarchy.

Two compact-width options considered:
1. Keep the full input/search/filter/sort stack, improve surfaces and typography.
2. Keep a compact add/search area, use one Material segmented filter, move sort
   and rare bulk actions to the app bar, and place row actions in an overflow
   menu.

Choose option 2: it preserves visible primary actions and selected scope while
giving task rows more room. Sort remains visible as a criterion in the list
header (`По добавлению`, `А–Я` or `Я–А`) and selected in the menu. Search remains directly available with a clear
action. Per-task edit, duplicate and delete remain explicitly available by
menu. Deleting completed tasks still confirms its full stored-record scope.

## Rules and acceptance

- Filter, query and sort are independent view state; changing one does not
  reset the others or mutate persisted order. Active count always includes all
  stored unfinished tasks.
- Keep loading, load failure/retry, truly empty, filtered-empty and no-search-
  results states distinct. Failed writes retain saved data and retryable drafts.
- For a populated 390px compact screen, the list header and first task should
  follow the compact controls without a full-width add button, sort field or
  three permanent row action icons. Long task names wrap to two lines at most;
  selection, current sort and all task actions remain understandable.
- Verify filter/search/sort independence, task operations and rejected writes
  using existing widget/repository acceptance tests; inspect representative
  runtime light/dark captures and the empty/error states remain covered by tests.
