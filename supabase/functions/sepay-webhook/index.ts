import { createClient } from "npm:@supabase/supabase-js@2";

import { createSepayHandler, type PaymentStore } from "./handler.ts";

const env = (name: string) => Deno.env.get(name);

function serviceStore(): PaymentStore {
  const client = createClient(
    env("SUPABASE_URL")!,
    env("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  return {
    async record(event) {
      const { error } = await client.from("payment_events").insert({
        provider: "sepay",
        provider_id: event.providerId,
        amount: event.amount,
        content: event.content,
        payload: event.payload,
      });
      if (!error) return true;
      if (error.code === "23505") return false;
      throw new Error(`record: ${error.message}`);
    },
    async findPending(code) {
      const { data, error } = await client
        .from("pro_upgrade_requests")
        .select("id, amount, plan")
        .eq("transfer_code", code)
        .eq("status", "pending")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) throw new Error(`find: ${error.message}`);
      if (!data) return null;
      const { data: price } = await client.rpc("pro_plan_price", {
        p_plan: data.plan,
      });
      return { id: data.id, amount: Number(data.amount ?? price ?? 0) };
    },
    async approve(requestId, ref) {
      const { error } = await client.rpc("approve_pro_request", {
        p_request_id: requestId,
        p_note: "SePay",
      });
      if (error) throw new Error(`approve: ${error.message}`);
      await client
        .from("pro_upgrade_requests")
        .update({ paid_at: new Date().toISOString(), payment_ref: ref })
        .eq("id", requestId);
    },
    async mark(providerId, status, requestId) {
      await client
        .from("payment_events")
        .update({ status, request_id: requestId ?? null })
        .eq("provider", "sepay")
        .eq("provider_id", providerId);
    },
  };
}

Deno.serve(
  createSepayHandler({ apiKey: env("SEPAY_API_KEY"), store: serviceStore }),
);
