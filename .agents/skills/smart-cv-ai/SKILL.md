---
name: smart-cv-ai
description: Builds and reviews Smart CV Maker AI features (CV interview chat, AI resume parsing, summary/bullet rewriting, cover letters, JD tailoring) through the `cv-assistant` Supabase Edge Function and OpenRouter, including Free/Pro quota, prompt-injection defence and user-data privacy. Use when adding or changing any AI-powered behavior, prompts, models, quota rules, or AI error handling in this repository.
---

# Smart CV AI

## Required context

Read `AGENTS.md`, `docs/ai-assistant.md`, `supabase/functions/cv-assistant/`, the quota migration under `supabase/migrations/`, and `lib/features/ai_tools/` before editing.

## Architecture (do not bypass)

```
Flutter widget → Riverpod controller → AiAssistantRepository
  → AiAssistantRemoteDataSource (supabase.functions.invoke, user JWT)
    → Edge Function `cv-assistant` (verifies JWT, validates input, consumes quota)
      → OpenRouter chat completions (OPENROUTER_API_KEY secret, model fallback list)
```

- The OpenRouter key exists only as a Supabase function secret (`supabase secrets set OPENROUTER_API_KEY=...`) or in the ignored `supabase/functions/.env` for local serving. It must never appear in the Flutter `.env`, Dart code, tests, logs, docs or Git history.
- Guests cannot call AI. The client checks for a session first; the function rejects missing/invalid JWTs with 401.
- Quota is enforced in the database by `public.consume_ai_credits(cost)` (security definer, uses `auth.uid()`), never by the client. Clients only display the `quota` object returned by the function.
- Plans come from `public.user_entitlements` which users cannot write. Defaults: Free = small daily credit budget, Pro = larger budget. Change the numbers in the migration/secret, not in Dart.

## Adding an action

1. Add the action name to the `actions` table in `cv-assistant/index.ts` with its credit cost, input validator and max input size.
2. Write the prompt in `prompts.ts`: system message states the task and output JSON schema; user data goes inside `<cv_data>` / `<user_message>` tags and is declared untrusted.
3. Ask for JSON output, parse defensively, clamp lengths, and drop unknown fields.
4. Map the response into a domain model in `lib/features/ai_tools/domain/models/`.
5. Add Dart unit tests with a fake repository and a Deno test with a mocked `fetch`; never call OpenRouter in automated tests.
6. Update `docs/ai-assistant.md` (contract, cost, errors).

## Prompt and output rules

- Never invent employers, dates, degrees, metrics or certifications; ask the user instead.
- Keep the user's language (`vi`/`en`) unless they ask otherwise.
- Return plain text fields — no Markdown inside CV fields.
- Results are suggestions: the UI shows a preview and the user confirms before anything is saved.

## Privacy

- Send the minimum: extracted text, not the original file; trim to the action's limit.
- Do not log prompts, CV content, emails, phone numbers or tokens in the function. Log only action, status, latency and model id.
- Show a one-time consent notice before the first upload of CV content to AI.

## Error contract

| Status | `code` | Client message intent |
| --- | --- | --- |
| 401 | `unauthenticated` | Ask to sign in |
| 402 | `quota_exceeded` | Show remaining credits + upgrade path |
| 413/422 | `invalid_input` | Explain the limit |
| 429 | `rate_limited` | Retry after a short wait |
| 503 | `provider_unavailable` | All models failed; local data untouched |

## Validation

```bash
flutter test test/features/ai_tools
npx -y deno test supabase/functions/cv-assistant   # when Deno is available
```

Never paste the real key into commands that are logged; read it from the env file.
