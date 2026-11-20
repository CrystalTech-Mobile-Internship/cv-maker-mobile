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

function fakeStore(pending: Record<string, { id: string; amount: number }>) {
  const seen = new Set<string>();
  const log: string[] = [];
  const store: PaymentStore = {
    record: (e) => {
      if (seen.has(e.providerId)) return Promise.resolve(false);
      seen.add(e.providerId);
      return Promise.resolve(true);
    },
    findPending: (code) => Promise.resolve(pending[code] ?? null),
    approve: (id) => {
      log.push(`approve ${id}`);
      return Promise.resolve();
    },
    mark: (pid, status) => {
      log.push(`${pid} ${status}`);
      return Promise.resolve();
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
  transferAmount: 99000,
  content: "NGUYEN VAN A chuyen tien CVPRO L1A2B3C4D FT2611",
  referenceCode: "FT2611",
  ...over,
});

Deno.test("finds the code even when the bank adds spaces and dashes", () => {
  assertEquals(findCheckoutCode("ck cvpro-l1a2b3c4d tks"), "CVPROL1A2B3C4D");
  assertEquals(findCheckoutCode(null, "MBVCB.123.CVPROM0F1E2D3C"), "CVPROM0F1E2D3C");
  assertEquals(findCheckoutCode("no code here"), null);
});

Deno.test("rejects calls without the right key", async () => {
  const { store } = fakeStore({});
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });
  assertEquals((await handler(post(transfer(), "wrong"))).status, 401);
});

Deno.test("approves a matching transfer once", async () => {
  const { store, log } = fakeStore({
    CVPROL1A2B3C4D: { id: "req-1", amount: 99000 },
  });
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  assertEquals((await handler(post(transfer()))).status, 200);
  assertEquals((await handler(post(transfer()))).status, 200);
  assertEquals(log, ["approve req-1", "101 matched"]);
});

Deno.test("does not approve when the amount is too low", async () => {
  const { store, log } = fakeStore({
    CVPROL1A2B3C4D: { id: "req-1", amount: 99000 },
  });
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  await handler(post(transfer({ transferAmount: 49000 })));
  assertEquals(log, ["101 unmatched"]);
});

Deno.test("ignores outgoing transfers", async () => {
  const { store, log } = fakeStore({
    CVPROL1A2B3C4D: { id: "req-1", amount: 99000 },
  });
  const handler = createSepayHandler({ apiKey: "secret", store: () => store });

  await handler(post(transfer({ transferType: "out" })));
  assertEquals(log, ["101 ignored"]);
});
