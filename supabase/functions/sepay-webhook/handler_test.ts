import {
  createSepayHandler,
  findCheckoutCode,
  type PaymentStore,
} from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown) {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`Expected ${b}, got ${a}`);
}

/** Mimics the database: one row per SePay id, matched at most once. */
function fakeStore(opts: { failApplyOnce?: boolean } = {}) {
  const status = new Map<string, string>();
  const log: string[] = [];
  let failNext = opts.failApplyOnce ?? false;
  const store: PaymentStore = {
    record: (e) => {
      if (!status.has(e.providerId)) status.set(e.providerId, "received");
      return Promise.resolve();
    },
    ignore: (pid) => {
      if (status.get(pid) === "received") status.set(pid, "ignored");
      log.push(`${pid} ignored`);
      return Promise.resolve();
    },
    apply: (pid, code) => {
      if (failNext) {
        failNext = false;
        return Promise.reject(new Error("permission denied"));
      }
      const current = status.get(pid)!;
      if (current !== "received") return Promise.resolve(current);
      const next = code ? "matched" : "unmatched";
      status.set(pid, next);
      log.push(`${pid} ${next} ${code ?? "-"}`);
      return Promise.resolve(next);
    },
  };
  return { store, log };
}

const post = (body: unknown, key = "secret") =>
  new Request("https://x/sepay-webhook", {
    method: "POST",
    headers: { Authorization: `Apikey ${key}` },
    body: JSON.stringify(body),
  });

const transfer = (over: Record<string, unknown> = {}) => ({
  id: 101,
  transferType: "in",
  transferAmount: 119000,
  content: "NGUYEN VAN A chuyen tien CVPRO Q1A2B3C4D FT2611",
  referenceCode: "FT2611",
  ...over,
});

Deno.test("finds the code even when the bank adds spaces and dashes", () => {
  assertEquals(findCheckoutCode("ck cvpro-q1a2b3c4d tks"), "CVPROQ1A2B3C4D");
  assertEquals(findCheckoutCode(null, "MBVCB.123.CVPROM0F1E2D3C"), "CVPROM0F1E2D3C");
  assertEquals(findCheckoutCode("no code here"), null);
});

Deno.test("rejects calls without the right key", async () => {
  const { store } = fakeStore();
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });
  assertEquals((await handler(post(transfer(), "wrong"))).status, 401);
});

Deno.test("matches a transfer once even when SePay sends it twice", async () => {
  const { store, log } = fakeStore();
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  assertEquals((await handler(post(transfer()))).status, 200);
  assertEquals((await handler(post(transfer()))).status, 200);
  assertEquals(log, ["101 matched CVPROQ1A2B3C4D"]);
});

Deno.test("a retry after a failure still activates Pro", async () => {
  const { store, log } = fakeStore({ failApplyOnce: true });
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  let firstStatus = 0;
  try {
    firstStatus = (await handler(post(transfer()))).status;
  } catch (_) {
    firstStatus = 500; // Deno.serve turns a thrown error into a 500.
  }
  assertEquals(firstStatus, 500);
  assertEquals((await handler(post(transfer()))).status, 200);
  assertEquals(log, ["101 matched CVPROQ1A2B3C4D"]);
});

Deno.test("transfers without a code are kept as unmatched", async () => {
  const { store, log } = fakeStore();
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  await handler(post(transfer({ content: "chuyen tien", id: 7 })));
  assertEquals(log, ["7 unmatched -"]);
});

Deno.test("ignores outgoing transfers", async () => {
  const { store, log } = fakeStore();
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  await handler(post(transfer({ transferType: "out" })));
  assertEquals(log, ["101 ignored"]);
});
