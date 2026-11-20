/**
 * SePay bank-transfer webhook.
 *
 * SePay calls this for every transaction on the linked bank account, with
 * `Authorization: Apikey <key>`. Incoming transfers whose note contains a
 * Pro checkout code (e.g. `CVPROL1A2B3C4D`) and whose amount covers the
 * price upgrade the account right away.
 */

export type SepayPayload = {
  id?: number | string;
  gateway?: string;
  transactionDate?: string;
  accountNumber?: string;
  code?: string | null;
  content?: string | null;
  description?: string | null;
  transferType?: string;
  transferAmount?: number | string;
  referenceCode?: string | null;
};

export type PendingRequest = { id: string; amount: number };

export type PaymentStore = {
  /** Records the event; returns false when this SePay id was seen before. */
  record(event: {
    providerId: string;
    amount: number;
    content: string;
    payload: SepayPayload;
  }): Promise<boolean>;
  findPending(code: string): Promise<PendingRequest | null>;
  approve(requestId: string, ref: string): Promise<void>;
  mark(
    providerId: string,
    status: "matched" | "unmatched" | "ignored",
    requestId?: string,
  ): Promise<void>;
};

const CODE = /CVPRO[ML][0-9A-F]{8}/;

/** Finds a checkout code in a bank note, ignoring spaces and symbols. */
export function findCheckoutCode(...notes: (string | null | undefined)[]) {
  for (const note of notes) {
    if (!note) continue;
    const compact = note.toUpperCase().replace(/[^A-Z0-9]/g, "");
    const match = compact.match(CODE);
    if (match) return match[0];
  }
  return null;
}

/** Constant-time comparison so the key cannot be guessed by timing. */
function sameSecret(a: string, b: string) {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let diff = left.length ^ right.length;
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return diff === 0;
}

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

export function createSepayHandler(deps: {
  apiKey: string | undefined;
  store: () => PaymentStore;
}) {
  return async (req: Request): Promise<Response> => {
    if (req.method !== "POST") return json(405, { success: false });
    if (!deps.apiKey) return json(503, { success: false });

    const auth = req.headers.get("Authorization") ?? "";
    const given = auth.replace(/^Apikey\s+/i, "").trim();
    if (!given || !sameSecret(given, deps.apiKey)) {
      return json(401, { success: false });
    }

    let payload: SepayPayload;
    try {
      payload = await req.json();
    } catch (_) {
      return json(400, { success: false });
    }
    if (payload.id === undefined || payload.id === null) {
      return json(400, { success: false });
    }

    const store = deps.store();
    const providerId = String(payload.id);
    const amount = Math.round(Number(payload.transferAmount ?? 0));
    const content = `${payload.content ?? ""}`.slice(0, 500);

    const isNew = await store.record({ providerId, amount, content, payload });
    // SePay retries until it gets a success; a repeat is already handled.
    if (!isNew) return json(200, { success: true });

    if (payload.transferType !== "in") {
      await store.mark(providerId, "ignored");
      return json(200, { success: true });
    }

    const code = findCheckoutCode(payload.code, payload.content, payload.description);
    const request = code ? await store.findPending(code) : null;
    if (!request || amount < request.amount) {
      await store.mark(providerId, "unmatched", request?.id);
      return json(200, { success: true });
    }

    await store.approve(request.id, payload.referenceCode ?? providerId);
    await store.mark(providerId, "matched", request.id);
    return json(200, { success: true });
  };
}
