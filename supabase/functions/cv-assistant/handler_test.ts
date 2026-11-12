import { createHandler, type Quota, type QuotaStore } from "./handler.ts";
import { extractJsonObject, sanitizeCvDraft } from "./actions.ts";
import { createOpenRouterComplete, ProviderError } from "./openrouter.ts";

function assertEquals(actual: unknown, expected: unknown, message = "") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected ${e}\nactual   ${a}`);
}

function memoryQuota(limit: number) {
  let used = 0;
  const refunds: number[] = [];
  const store: QuotaStore = {
    consume(cost) {
      if (used + cost > limit) {
        return Promise.resolve({
          allowed: false,
          plan: "free",
          used,
          limit,
          remaining: limit - used,
        } as Quota);
      }
      used += cost;
      return Promise.resolve({
        allowed: true,
        plan: "free",
        used,
        limit,
        remaining: limit - used,
      });
    },
    refund(cost) {
      used -= cost;
      refunds.push(cost);
      return Promise.resolve();
    },
    current: () =>
      Promise.resolve({ plan: "free", used, limit, remaining: limit - used }),
  };
  return { store, refunds, used: () => used };
}

function post(body: unknown, auth = true) {
  return new Request("http://localhost/cv-assistant", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(auth ? { Authorization: "Bearer test" } : {}),
    },
    body: JSON.stringify(body),
  });
}

const interviewBody = {
  action: "interview",
  input: {
    language: "vi",
    messages: [{
      role: "user",
      content: "Tôi muốn ứng tuyển Flutter Developer",
    }],
  },
};

Deno.test("rejects requests without a session", async () => {
  const handler = createHandler({
    authenticate: () => Promise.resolve(null),
    complete: () => Promise.reject(new Error("should not be called")),
    log: () => {},
  });
  const response = await handler(post(interviewBody, false));
  assertEquals(response.status, 401);
  assertEquals((await response.json()).code, "unauthenticated");
});

Deno.test("returns parsed interview reply and quota", async () => {
  const quota = memoryQuota(3);
  const handler = createHandler({
    authenticate: () => Promise.resolve(quota.store),
    complete: () =>
      Promise.resolve({
        text:
          '```json\n{"reply":"Bạn học trường nào?","progress":20,"readyToGenerate":false}\n```',
        model: "fake",
      }),
    log: () => {},
  });
  const response = await handler(post(interviewBody));
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.result.reply, "Bạn học trường nào?");
  assertEquals(body.quota, { plan: "free", used: 1, limit: 3, remaining: 2 });
});

Deno.test("blocks calls when the free quota is exhausted", async () => {
  const quota = memoryQuota(2);
  let calls = 0;
  const handler = createHandler({
    authenticate: () => Promise.resolve(quota.store),
    complete: () => {
      calls++;
      return Promise.resolve({ text: '{"reply":"ok"}', model: "fake" });
    },
    log: () => {},
  });
  await handler(post(interviewBody));
  await handler(post(interviewBody));
  const response = await handler(post(interviewBody));
  assertEquals(response.status, 402);
  assertEquals((await response.json()).code, "quota_exceeded");
  assertEquals(calls, 2);
});

Deno.test("refunds credits when the provider fails", async () => {
  const quota = memoryQuota(5);
  const handler = createHandler({
    authenticate: () => Promise.resolve(quota.store),
    complete: () => Promise.reject(new ProviderError("HTTP_429")),
    log: () => {},
  });
  const response = await handler(post(interviewBody));
  assertEquals(response.status, 503);
  assertEquals(quota.refunds, [1]);
  assertEquals(quota.used(), 0);
});

Deno.test("validates input before spending credits", async () => {
  const quota = memoryQuota(5);
  const handler = createHandler({
    authenticate: () => Promise.resolve(quota.store),
    complete: () => Promise.reject(new Error("unused")),
    log: () => {},
  });
  const response = await handler(
    post({ action: "parse_resume", input: { text: "quá ngắn" } }),
  );
  assertEquals(response.status, 422);
  assertEquals(quota.used(), 0);
});

Deno.test("sanitizes AI CV drafts", () => {
  const draft = sanitizeCvDraft({
    fullName: "  Nguyễn Văn A ",
    skills: ["Flutter", "", 42],
    experiences: [
      {
        jobTitle: "Intern",
        company: "ABC",
        startDate: "2024/3",
        isCurrent: "true",
      },
      { foo: "bar" },
    ],
    educations: [{ institution: "", degree: "x" }],
  });
  assertEquals(draft.fullName, "Nguyễn Văn A");
  assertEquals(draft.skills, ["Flutter", "42"]);
  assertEquals(draft.experiences.length, 1);
  assertEquals(draft.experiences[0].startDate, "2024-03");
  assertEquals(draft.experiences[0].isCurrent, true);
  assertEquals(draft.educations.length, 0);
});

Deno.test("extracts JSON from noisy replies", () => {
  assertEquals(extractJsonObject('Here: {"a":1} thanks'), { a: 1 });
  assertEquals(extractJsonObject("no json"), null);
});

Deno.test("falls back to the next model when one fails", async () => {
  const seen: string[] = [];
  const fakeFetch = (async (_url: string, init: RequestInit) => {
    const model = JSON.parse(String(init.body)).model as string;
    seen.push(model);
    if (model === "a") return new Response("busy", { status: 429 });
    return new Response(
      JSON.stringify({ choices: [{ message: { content: "hello" } }] }),
    );
  }) as unknown as typeof fetch;
  const complete = createOpenRouterComplete(
    (name) =>
      ({ OPENROUTER_API_KEY: "k", OPENROUTER_MODELS: "a,b" } as Record<
        string,
        string
      >)[name],
    fakeFetch,
  );
  const result = await complete([{ role: "user", content: "hi" }], {
    maxTokens: 10,
    temperature: 0,
    json: false,
  });
  assertEquals(result, { text: "hello", model: "b" });
  assertEquals(seen, ["a", "b"]);
});

import { partialJsonString } from "./actions.ts";

Deno.test("recovers reply from truncated JSON", () => {
  const text = '{"reply": "Chào bạn!\nBạn học \\"ngành\\" gì? Và';
  assertEquals(
    partialJsonString(text, "reply"),
    'Chào bạn!\nBạn học "ngành" gì? Và',
  );
});
