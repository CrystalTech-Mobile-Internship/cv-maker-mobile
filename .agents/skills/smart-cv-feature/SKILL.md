---
name: smart-cv-feature
description: Implements and refactors Smart CV Maker Flutter features using Riverpod, GoRouter, offline-first persistence, and testable architecture. Use when adding screens, CV models, editor behavior, local storage, preview, PDF, or feature-level tests in this repository.
---

# Smart CV Feature

## Required context

Read `AGENTS.md`, `docs/requirements.md`, and `docs/mvp-flow.md`. Inspect the relevant feature, dependency declarations, tests, and Git status before editing.

## Workflow

1. State the user-visible outcome and acceptance criteria.
2. Identify the smallest complete vertical slice.
3. Preserve existing unrelated work.
4. Implement domain/data behavior before wiring final UI state.
5. Handle loading, empty, offline, success, and error states that apply.
6. Add or update tests.
7. Format, analyze, test, and review the diff.

## Architecture rules

- Keep Widgets focused on rendering and user interaction.
- Put mutable feature state behind Riverpod providers/notifiers.
- Keep data access behind repositories; do not call Supabase directly from Widgets.
- Treat local persistence as the runtime source of truth.
- Save locally before cloud synchronization.
- Identify CV operations with `cvId`; do not depend on one global sample CV.
- Prefer immutable models with explicit serialization and `copyWith` behavior.
- Do not introduce a new dependency until the current dependencies and standard library are insufficient.
- Do not add placeholder behavior without labeling it in code and handoff notes.

## Data-safety checklist

- [ ] Edits survive navigation and app restart.
- [ ] Network failure does not discard local changes.
- [ ] Guest records remain usable without authentication.
- [ ] Validation errors do not erase form content.
- [ ] Delete operations require confirmation.
- [ ] Preview reads the selected CV rather than hard-coded data.

## Validation

Run the narrowest relevant test first, then:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Report commands that could not run and why. Do not commit or push unless explicitly requested.

