import { buildMail, createSupportHandler, type SupportMessage } from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown) {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`Expected ${b}, got ${a}`);
}

const ID = "11111111-2222-4333-8444-555555555555";

function setup(message: Partial<SupportMessage> = {}, sendOk = true) {
  const sent: string[] = [];
  const marked: string[] = [];
  const handler = createSupportHandler({
    caller: (req) =>
      Promise.resolve(
        req.headers.get("Authorization") === "Bearer good"
          ? { id: "user-1", email: "user@example.com" }
          : null,
      ),
    load: () =>
      Promise.resolve({
        id: ID,
        userId: "user-1",
        sender: "user",
        body: "Tôi chưa nhận được Pro <b>",
        emailedAt: null,
        createdAt: "2026-11-20T08:00:00Z",
        ...message,
      }),
    markEmailed: (id) => {
      marked.push(id);
      return Promise.resolve();
    },
    send: (mail) => {
      sent.push(mail.subject);
      return Promise.resolve(sendOk);
    },
  });
  return { handler, sent, marked };
}

const call = (token = "good", id = ID) =>
  new Request("https://x/support-notify", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ messageId: id }),
  });

Deno.test("emails the owner's new message once", async () => {
  const { handler, sent, marked } = setup();
  assertEquals((await handler(call())).status, 200);
  assertEquals(sent.length, 1);
  assertEquals(marked, [ID]);
});

Deno.test("does not email a message twice", async () => {
  const { handler, sent } = setup({ emailedAt: "2026-11-20T08:01:00Z" });
  assertEquals((await handler(call())).status, 200);
  assertEquals(sent.length, 0);
});

Deno.test("refuses other users and signed-out callers", async () => {
  const other = setup({ userId: "user-2" });
  assertEquals((await other.handler(call())).status, 404);
  assertEquals(other.sent.length, 0);
  assertEquals((await setup().handler(call("bad"))).status, 401);
});

Deno.test("keeps the message unsent when the mail service fails", async () => {
  const { handler, marked } = setup({}, false);
  assertEquals((await handler(call())).status, 502);
  assertEquals(marked, []);
});

Deno.test("escapes HTML and replies to the user", () => {
  const mail = buildMail(
    {
      id: ID,
      userId: "user-1",
      sender: "user",
      body: "<script>x</script>",
      emailedAt: null,
      createdAt: "now",
    },
    "user@example.com",
  );
  assertEquals(mail.html.includes("<script>"), false);
  assertEquals(mail.replyTo, "user@example.com");
});
