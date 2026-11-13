import { createClient } from "npm:@supabase/supabase-js@2";

import { createHandler, type Quota, type QuotaStore } from "./handler.ts";
import { createOpenRouterComplete } from "./openrouter.ts";

const env = (name: string) => Deno.env.get(name);

function publishableKey(): string | undefined {
  try {
    const keys = JSON.parse(env("SUPABASE_PUBLISHABLE_KEYS") ?? "{}") as Record<
      string,
      string
    >;
    return keys.default ?? env("SUPABASE_ANON_KEY");
  } catch (_) {
    return env("SUPABASE_ANON_KEY");
  }
}

/**
 * Builds a Supabase client that acts as the caller (their JWT), so the quota
 * RPCs resolve `auth.uid()` server-side and RLS stays in force.
 */
async function authenticate(req: Request): Promise<QuotaStore | null> {
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return null;
  const url = env("SUPABASE_URL");
  const key = publishableKey();
  if (!url || !key) return null;

  const client = createClient(url, key, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) return null;

  const rpc = async (name: string, args?: Record<string, unknown>) => {
    const { data: value, error: rpcError } = await client.rpc(name, args);
    if (rpcError) throw new Error(`RPC_${name}`);
    return value as Quota;
  };

  return {
    consume: (cost) => rpc("consume_ai_credits", { p_cost: cost }),
    refund: async (cost) => {
      await rpc("refund_ai_credits", { p_cost: cost });
    },
    current: () => rpc("get_ai_quota"),
  };
}

Deno.serve(
  createHandler({
    authenticate,
    complete: createOpenRouterComplete(env),
  }),
);
