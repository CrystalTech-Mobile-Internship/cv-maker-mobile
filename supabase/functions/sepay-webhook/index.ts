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
      // 23505: already recorded by an earlier delivery of the same event.
      if (error && error.code !== "23505") {
        throw new Error(`record: ${error.message}`);
      }
    },
    async ignore(providerId) {
      const { error } = await client
        .from("payment_events")
        .update({ status: "ignored" })
        .eq("provider", "sepay")
        .eq("provider_id", providerId)
        .eq("status", "received");
      if (error) throw new Error(`ignore: ${error.message}`);
    },
    async apply(providerId, code, ref) {
      const { data, error } = await client.rpc("apply_sepay_payment", {
        p_provider_id: providerId,
        p_code: code,
        p_ref: ref,
      });
      if (error) throw new Error(`apply: ${error.message}`);
      return String(data);
    },
  };
}

Deno.serve(
  createSepayHandler({ apiKey: env("SEPAY_API_KEY"), store: serviceStore }),
);
