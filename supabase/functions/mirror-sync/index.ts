// Scheduled replication to the mirror Supabase project.
// Invoked by pg_cron with the `x-mirror-secret` header (see
// docs/dual-supabase-sync.md). Not callable by app users.

import { createClient } from "npm:@supabase/supabase-js@2";

import { runMirrorPass } from "./mirror.ts";
import { supabaseSource, supabaseTarget } from "./stores.ts";

const env = (name: string) => Deno.env.get(name) ?? "";

function safeEqual(a: string, b: string): boolean {
  if (!a || !b || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ message: "Method not allowed." }, 405);
  }
  if (
    !safeEqual(
      req.headers.get("x-mirror-secret") ?? "",
      env("MIRROR_CRON_SECRET"),
    )
  ) {
    return json({ message: "Forbidden." }, 403);
  }

  const targetUrl = env("MIRROR_SUPABASE_URL");
  const targetKey = env("MIRROR_SERVICE_ROLE_KEY");
  if (!targetUrl || !targetKey) {
    return json({ message: "Mirror target is not configured." }, 503);
  }

  const options = { auth: { persistSession: false, autoRefreshToken: false } };
  const source = createClient(
    env("SUPABASE_URL"),
    env("SUPABASE_SERVICE_ROLE_KEY"),
    options,
  );
  const target = createClient(targetUrl, targetKey, options);
  const targetName = env("MIRROR_TARGET_NAME") || new URL(targetUrl).host;

  const started = Date.now();
  try {
    const report = await runMirrorPass(
      supabaseSource(source, targetName),
      supabaseTarget(target),
    );
    console.log(
      JSON.stringify({
        target: targetName,
        ...report,
        ms: Date.now() - started,
      }),
    );
    return json(report);
  } catch (error) {
    console.log(JSON.stringify({
      target: targetName,
      error: error instanceof Error ? error.message : "UNKNOWN",
    }));
    return json({ message: "Mirror pass failed." }, 500);
  }
});
