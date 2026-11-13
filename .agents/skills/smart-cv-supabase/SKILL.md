---
name: smart-cv-supabase
description: Designs and verifies Smart CV Maker Supabase Auth, PostgreSQL migrations, Row-Level Security, Edge Functions, the primary/secondary dual-project mirror, community tables, and offline synchronization. Use when changing Supabase configuration, schema, policies, authentication, cloud repositories, replication between the two projects, or sync behavior in this repository.
---

# Smart CV Supabase

## Required context

Read `AGENTS.md`, the cloud requirements in `docs/requirements.md`, the data flows in `docs/mvp-flow.md`, current environment helpers, and existing migrations before making changes.

## Workflow

1. Define the client operation and required user identity.
2. Design the schema and offline mapping together.
3. Add a timestamped migration under `supabase/migrations/`.
4. Enable RLS and create the minimum explicit policies.
5. Update the Flutter repository boundary; keep Supabase out of Widgets.
6. Verify Guest Mode and network failure behavior.
7. Test data isolation with two users.
8. Update `.env.example` and setup documentation when configuration changes.

## Dual-project topology

The app is configured with two Supabase projects (`SUPABASE_PRIMARY_*`, `SUPABASE_SECONDARY_*`) and `SUPABASE_ACTIVE_PROFILE` selects one per app run.

- Auth users, JWTs and user ids are project-specific. Never switch the client between projects mid-session and never reuse a user id from one project in the other.
- The device's Drift database is the bridge between projects: CV ids are stable UUIDs, so a CV pushed to either project keeps its id.
- Server-to-server mirroring runs only in the `mirror-sync` Edge Function with the *other* project's service-role key stored as a function secret. Users are matched by verified email; rows are copied with the mirror user's id.
- Every migration must be idempotent (`if not exists`, `on conflict`, `drop ... if exists`) and applied to **both** projects in the same order. Record which project received it.
- Before declaring sync complete, compare row counts per user on both projects.

## Security requirements

- Use only a Supabase publishable/anonymous client key in the mobile app.
- Never expose a secret key, service-role key, database password, or private server token.
- Enable RLS on every exposed user-owned table.
- Scope policies with `auth.uid() = user_id` or an equally strict ownership relation.
- Add `WITH CHECK` to insert/update policies so ownership cannot be reassigned.
- Do not rely on a hidden client key as access control; RLS is the enforcement boundary.
- Function secrets (AI keys, mirror service-role key) live only in `supabase secrets` / `supabase/functions/.env` (ignored). The Flutter `.env` is bundled into the app and must never hold them.
- Do not execute destructive SQL against a shared or production project without explicit approval and a recovery plan.

## Synchronization requirements

- Write to local storage first.
- Mark unsynchronized changes explicitly.
- Use UTC timestamps for sync comparisons.
- Make retries idempotent.
- Do not delete local Guest data automatically after login.
- Document the conflict rule and test it before claiming multi-device sync support.

## Completion evidence

Provide the migration path, affected Dart files, policy summary, two-user isolation result, offline behavior result, and suggested commit message. Do not commit or push unless explicitly requested.

