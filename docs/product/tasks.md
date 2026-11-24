# Task list behavior

The screen is for adding, finding and completing tasks while retaining existing
task records and actions (edit, duplicate, delete, and confirmed deletion of all
completed tasks).

- Search matches trimmed, case-insensitive titles. Search, status filter and
  sort are independent, in-memory view settings and never rewrite storage.
- All shows active tasks first and completed tasks second. Active and completed
  filters show only that status. Search and filter select records; sorting then
  orders each status group independently. Default order is stored order;
  A–Я and Я–А compare titles case-insensitively using Russian letter order
  (Ё immediately follows Е), preserving stored order for ties.
- The active count covers every saved active task, regardless of visible search
  or filter. Empty storage, no search matches and an empty status filter have
  distinct states. Load failures can be retried; failed writes leave saved
  records unchanged and adding retains its draft.
- Completing a task moves it between groups. Renaming may change its position
  or remove it from search results. Sorting never changes deletion scope.

Visual direction: content-first Material 3 list with a compact add form,
discoverable search/filter/sort controls, clear active and completed headings,
and existing contextual row actions. Preserve the single-column layout and
adapt through the existing bounded content width.

Acceptance: with active B,A,C and completed E,F,D in stored order, All/default
shows B,A,C then E,F,D; A–Я shows A,B,C then D,E,F; Я–А shows C,B,A then F,E,D.
Searching D while All/A–Я shows only completed D, and clearing the query restores
both sorted groups without changing storage. In either filtered scope, only
matching status rows appear.
