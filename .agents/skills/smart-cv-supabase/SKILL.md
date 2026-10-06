---
name: smart-cv-supabase
description: Designs and verifies Smart CV Maker Supabase Auth, PostgreSQL migrations, Row-Level Security, Storage, and offline synchronization. Use when changing Supabase configuration, schema, policies, authentication, cloud repositories, or sync behavior in this repository.
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

## Security requirements

- Use only a Supabase publishable/anonymous client key in the mobile app.
- Never expose a secret key, service-role key, database password, or private server token.
- Enable RLS on every exposed user-owned table.
- Scope policies with `auth.uid() = user_id` or an equally strict ownership relation.
- Add `WITH CHECK` to insert/update policies so ownership cannot be reassigned.
- Do not rely on a hidden client key as access control; RLS is the enforcement boundary.
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

