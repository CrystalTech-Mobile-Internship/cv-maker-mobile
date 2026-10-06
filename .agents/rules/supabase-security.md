---
trigger: glob
description: Supabase migration, RLS, credential, and synchronization rules
globs: "lib/**/*.dart, supabase/**/*.sql, .env.example"
---

# Supabase and Data Security

- Keep schema changes in timestamped files under `supabase/migrations/`.
- Enable RLS on every exposed table containing user-owned data.
- Scope access to the authenticated owner and include `WITH CHECK` for writes.
- Use a publishable/anonymous client key only; never ship secret or service-role keys.
- Keep `.env` ignored and `.env.example` limited to placeholders.
- Store UTC timestamps and update `updated_at` consistently.
- Make synchronization retryable and idempotent.
- Save local changes before sending cloud mutations.
- Never delete Guest data automatically during sign-in or sync.
- Test policies with two distinct users before declaring RLS complete.
- Do not run destructive SQL on shared data without explicit approval.

