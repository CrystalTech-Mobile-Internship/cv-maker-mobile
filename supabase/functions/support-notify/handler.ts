/**
 * Emails a new support message to the support inbox.
 *
 * The app calls this right after saving a message. The inbox address and the
 * mail API key live in function secrets, never in the app.
 */

export type SupportMessage = {
  id: string;
  userId: string;
  sender: string;
  body: string;
  emailedAt: string | null;
  createdAt: string;
};

export type SupportDeps = {
  /** Returns the caller's user id and email from their JWT, or null. */
  caller(req: Request): Promise<{ id: string; email: string | null } | null>;
  load(messageId: string): Promise<SupportMessage | null>;
  markEmailed(messageId: string): Promise<void>;
  send(mail: {
    subject: string;
    text: string;
    html: string;
    replyTo: string | null;
  }): Promise<boolean>;
};

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

export function buildMail(
  message: SupportMessage,
  email: string | null,
) {
  const who = email ?? message.userId;
  const preview = message.body.replace(/\s+/g, " ").slice(0, 60);
  const text = [
    `Tin nhắn hỗ trợ mới từ ${who}`,
    "",
    message.body,
    "",
    `Mã tài khoản: ${message.userId}`,
    `Thời gian: ${message.createdAt}`,
    "",
    "Trả lời email này để phản hồi trực tiếp cho người dùng.",
  ].join("\n");
  const html = `<p>Tin nhắn hỗ trợ mới từ <b>${escapeHtml(who)}</b></p>
<blockquote style="border-left:3px solid #4F46E5;margin:0;padding:8px 12px;white-space:pre-wrap">${
    escapeHtml(message.body)
  }</blockquote>
<p style="color:#64748B;font-size:12px">Mã tài khoản: ${
    escapeHtml(message.userId)
  }<br>Thời gian: ${escapeHtml(message.createdAt)}</p>
<p style="color:#64748B;font-size:12px">Trả lời email này để phản hồi trực tiếp cho người dùng.</p>`;
  return {
    subject: `[Smart CV hỗ trợ] ${preview}`,
    text,
    html,
    replyTo: email,
  };
}

export function createSupportHandler(deps: SupportDeps) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (req.method !== "POST") return json(405, { ok: false });

    const user = await deps.caller(req);
    if (!user) return json(401, { ok: false });

    let messageId = "";
    try {
      const body = await req.json();
      messageId = `${body?.messageId ?? ""}`;
    } catch (_) {
      return json(400, { ok: false });
    }
    if (!/^[0-9a-f-]{36}$/i.test(messageId)) return json(400, { ok: false });

    const message = await deps.load(messageId);
    // Only the owner can trigger the email for their own, unsent message.
    if (!message || message.userId !== user.id || message.sender !== "user") {
      return json(404, { ok: false });
    }
    if (message.emailedAt) return json(200, { ok: true, sent: false });

    const sent = await deps.send(buildMail(message, user.email));
    if (!sent) return json(502, { ok: false });
    await deps.markEmailed(message.id);
    return json(200, { ok: true, sent: true });
  };
}
