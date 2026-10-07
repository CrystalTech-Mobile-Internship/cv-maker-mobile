---
name: smart-cv-quality
description: Reviews and validates Smart CV Maker changes for correctness, data safety, Flutter quality, Supabase security, tests, and commit readiness. Use before commits, during code review, after feature implementation, or when diagnosing analyze/test failures in this repository.
---

# Smart CV Quality Gate

## Review sequence

1. Read `AGENTS.md` and the requirements affected by the change.
2. Inspect Git status and the diff without modifying unrelated files.
3. Check correctness and regression risk before style.
4. Check offline behavior and user-data preservation.
5. Check authentication, RLS, secrets, and ownership boundaries when relevant.
6. Check tests and documentation.
7. Run validation commands.

## Quality checklist

- [ ] Behavior matches `docs/mvp-flow.md`.
- [ ] No hard-coded production data or credentials.
- [ ] No direct Supabase access from Widgets.
- [ ] Local writes do not depend on cloud success.
- [ ] Selected CV is addressed by `cvId`.
- [ ] Loading, empty, offline, success, and error states are covered as needed.
- [ ] Tests cover success and the highest-risk failure path.
- [ ] Public configuration examples contain placeholders only.
- [ ] Comments describe intent, not obvious syntax.
- [ ] Documentation does not claim unfinished behavior is complete.

## Validation commands

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
```

## Report format

Report blocking findings first with file and line references. Then list validation results, residual risks, and a Conventional Commit suggestion. If no defects are found, say so explicitly while noting any unverified behavior.

