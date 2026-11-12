---
name: smart-cv-feature
description: Implements and refactors Smart CV Maker Flutter features using Riverpod, GoRouter, Drift offline-first persistence, and testable architecture. Use when adding screens, CV models, editor tools, drag-and-drop preview behavior, templates, PDF/DOCX export, resume import, community pages, or feature-level tests in this repository.
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

## Project map

| Area | Location | Notes |
| --- | --- | --- |
| CV aggregate | `lib/features/cv_editor/domain/models/cv_model.dart` | `sectionOrder`, `hiddenSections`, `language` (`vi`/`en`) are part of the CV and must survive save, backup, sync and export. |
| Local storage | `lib/core/database/` (Drift) | Source of truth at runtime; `payload_json` stores the full CV snapshot. |
| Editor | `lib/features/cv_editor/presentation/` | Tabs live in `widgets/`; helper sheets (skill bank, action verbs, starter samples, section reorder, typography toolbar). |
| Preview | `lib/features/cv_preview/` | A4 PDF preview, interactive drag-and-drop layout, template gallery, colour sheet, page fit, JD matcher. |
| Export | `cv_preview/data/services/` | Vector PDF (`pdf`), DOCX (OpenXML via `archive`). Both must honour `visibleSectionOrder`. |
| Import | `lib/features/resume_import/` | On-device DOCX/PDF text extraction + heuristic parser; AI parsing is an optional enhancement. |
| AI tools | `lib/features/ai_tools/` | Always via Supabase Edge Functions — see `smart-cv-ai`. |
| Templates | `cv_template.dart` + `AppConstants` | Every template id must also be seeded in the cloud `templates` table. |

## CV-building UX conventions

- Every new CV-assist tool must be usable offline unless it is an AI feature; AI features must degrade with a clear message, never a crash.
- Labels are bilingual: follow `cv.language` for content shown on the CV and Vietnamese for app chrome.
- Drag-and-drop and reorder interactions persist immediately through the repository and must update the PDF preview and both exporters.
- Bottom sheets for tools return values to the caller; the screen/controller performs the save.
- Suggestions (skills, keywords, AI text) are applied only after an explicit user action and must be undoable or editable.
- Never invent user facts in samples or suggestions; mark sample content as sample.

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
dart format <changed files only>
flutter analyze
flutter test
```

- Format only the files you changed; running `dart format lib` reformats unrelated files and pollutes the commit.
- Widget tests that scroll long `ListView`s should enlarge `tester.view.physicalSize` or use `scrollUntilVisible`.
- Screenshot tests write into `artifacts/` (ignored by Git).

Report commands that could not run and why. Do not commit or push unless explicitly requested.

## Git

- Branch from `develop` as `feature/<short-name>`, `fix/<short-name>` or `chore/<short-name>`; merge back with `git merge --no-ff` and a `merge: integrate <topic>` message.
- Commit messages are English Conventional Commits describing the change only — no tool attribution, `Co-Authored-By` trailers, or schedule references (week/day numbers).
- Commit with the repository's configured Git identity.

