import { createClient } from "npm:@supabase/supabase-js@2";

import { createSupportHandler } from "./handler.ts";

const env = (name: string) => Deno.env.get(name);

const admin = () =>
  createClient(env("SUPABASE_URL")!, env("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

Deno.serve(
  createSupportHandler({
    async caller(req) {
      const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
      if (!token) return null;
      const { data, error } = await admin().auth.getUser(token);
      if (error || !data.user) return null;
      return { id: data.user.id, email: data.user.email ?? null };
    },
    async load(messageId) {
      const { data } = await admin()
        .from("support_messages")
        .select("id, user_id, sender, body, emailed_at, created_at")
        .eq("id", messageId)
        .maybeSingle();
      if (!data) return null;
      return {
        id: data.id,
        userId: data.user_id,
        sender: data.sender,
        body: data.body,
        emailedAt: data.emailed_at,
        createdAt: data.created_at,
      };
    },
    async markEmailed(messageId) {
      await admin()
        .from("support_messages")
        .update({ emailed_at: new Date().toISOString() })
        .eq("id", messageId);
    },
    async send(mail) {
      const apiKey = env("RESEND_API_KEY");
      const inbox = env("SUPPORT_INBOX");
      if (!apiKey || !inbox) return false;
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: env("SUPPORT_FROM") ?? "Smart CV <onboarding@resend.dev>",
          to: [inbox],
          subject: mail.subject,
          text: mail.text,
          html: mail.html,
          ...(mail.replyTo ? { reply_to: mail.replyTo } : {}),
        }),
      });
      return response.ok;
    },
  }),
);
