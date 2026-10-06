# Smart CV Maker — Agent Guide

## Source of truth

Read these files before making product or architecture decisions:

1. `docs/requirements.md` — product requirements.
2. `docs/mvp-flow.md` — agreed MVP scope and user flows.
3. `docs/agent-workflow.md` — execution and handoff process.

If code and documentation disagree, report the mismatch before expanding the implementation.

## Multi-agent configuration

- `.agents/skills/` is the canonical source for project skills.
- `.codex/skills/`, `.claude/skills/`, and `.cursor/skills/` are compatibility entrypoints; keep their metadata aligned with the canonical skill.
- `CLAUDE.md` imports this file for Claude Code.
- Antigravity and Codex read this file directly.
- Platform-specific rules live in `.agents/rules/`, `.claude/rules/`, and `.cursor/rules/` because their activation frontmatter is not interchangeable.
- Update canonical skill content first. Compatibility entrypoints must contain only metadata and a pointer to the canonical file.

## Project principles

- Build an offline-first Flutter application; local persistence is the primary runtime source of truth.
- Save locally before attempting cloud synchronization.
- Use Riverpod for state management and GoRouter for navigation.
- Pass CV identity explicitly; editor and preview flows must operate on a `cvId`.
- Keep presentation, domain logic, and data access separable.
- Treat Supabase RLS as mandatory for every user-owned table.
- Never place secret, service-role, database, or private AI keys in the mobile application or Git.
- Preserve user data on network, authentication, synchronization, and PDF failures.
- Do not represent placeholders or mocked behavior as completed functionality.

## Agent workflow

For each task:

1. Inspect the relevant requirements, current implementation, Git status, and nearby tests.
2. State the intended outcome and identify assumptions.
3. Make the smallest complete change that satisfies the task.
4. Format and validate the affected code.
5. Review the diff for secrets, unrelated edits, regressions, and missing states.
6. Report changed files, validation results, known limitations, and a suggested commit message.

Do not commit, push, delete data, rewrite history, or execute destructive database operations unless the user explicitly requests it.

## Definition of done

A change is complete only when:

- Its behavior matches `docs/mvp-flow.md`.
- Loading, empty, offline, success, and error states relevant to the change are handled.
- User data is not lost when cloud access fails.
- Tests are added or updated in proportion to the risk.
- `dart format`, `flutter analyze`, and relevant `flutter test` commands pass, or failures are clearly reported.
- Documentation and `.env.example` are updated when configuration or behavior changes.

## Git conventions

- Work from `develop`; use `feature/<short-name>` for changes that span multiple files or days.
- Keep commits focused and use Conventional Commits: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.
- Never commit `.env`, generated build output, credentials, or production user data.
- Do not overwrite or discard unrelated working-tree changes.

