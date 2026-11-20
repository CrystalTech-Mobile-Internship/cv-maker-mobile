/**
 * SePay bank-transfer webhook.
 *
 * SePay calls this for every transaction on the linked bank account, with
 * `Authorization: Apikey <key>`. Incoming transfers whose note contains a
 * Pro checkout code (e.g. `CVPROQ1A2B3C4D`) and whose amount covers the
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

export type PaymentStore = {
  /** Records the event; a repeat of the same SePay id is ignored. */
  record(event: {
    providerId: string;
    amount: number;
    content: string;
    payload: SepayPayload;
  }): Promise<void>;
  /** Marks a money-out event so it is never matched. */
  ignore(providerId: string): Promise<void>;
  /**
   * Matches the event to a Pro purchase in one database transaction.
   * Safe to repeat: events already handled return their old status.
   */
  apply(
    providerId: string,
    code: string | null,
    ref: string,
  ): Promise<"matched" | "unmatched" | "ignored" | string>;
};

const CODE = /CVPRO[MQL][0-9A-F]{8}/;

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

    // Recording is idempotent and matching only touches events that were
    // not handled yet, so a retry after any failure finishes the job.
    await store.record({ providerId, amount, content, payload });

    if (payload.transferType !== "in") {
      await store.ignore(providerId);
      return json(200, { success: true });
    }

    const code = findCheckoutCode(payload.code, payload.content, payload.description);
    await store.apply(providerId, code, payload.referenceCode ?? providerId);
    return json(200, { success: true });
  };
}
