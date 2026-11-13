// Request pipeline: CORS → size limit → JWT → validation → quota → model.

import { actions } from "./actions.ts";
import { type CompleteFn, ProviderError } from "./openrouter.ts";
import { fetchJobPostingText, JobFetchError } from "./job_fetch.ts";

export type Quota = {
  allowed?: boolean;
  plan: string;
  used: number;
  limit: number;
  remaining: number;
};

export type QuotaStore = {
  consume: (cost: number) => Promise<Quota>;
  refund: (cost: number) => Promise<void>;
  current: () => Promise<Quota>;
};

export type Dependencies = {
  /** Returns a quota store bound to the caller, or null if unauthenticated. */
  authenticate: (req: Request) => Promise<QuotaStore | null>;
  complete: CompleteFn;
  fetchJob?: (url: string) => Promise<string>;
  log?: (entry: Record<string, unknown>) => void;
};

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const maxBodyBytes = 64 * 1024;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Cache-Control": "no-store",
      "Content-Type": "application/json",
    },
  });
}

function error(status: number, code: string, message: string, extra = {}) {
  return json({ code, message, ...extra }, status);
}

export function createHandler(deps: Dependencies) {
  const log = deps.log ?? ((entry) => console.log(JSON.stringify(entry)));

  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (req.method !== "POST") {
      return error(405, "method_not_allowed", "Method not allowed.");
    }

    const declared = Number(req.headers.get("content-length") ?? "0");
    if (Number.isFinite(declared) && declared > maxBodyBytes) {
      return error(413, "invalid_input", "Dữ liệu gửi lên quá lớn.");
    }

    const quotaStore = await deps.authenticate(req);
    if (!quotaStore) {
      return error(
        401,
        "unauthenticated",
        "Bạn cần đăng nhập để dùng chức năng này.",
      );
    }

    let body: Record<string, unknown>;
    try {
      const raw = await req.text();
      if (raw.length > maxBodyBytes) {
        return error(413, "invalid_input", "Dữ liệu gửi lên quá lớn.");
      }
      body = JSON.parse(raw);
    } catch (_) {
      return error(400, "invalid_input", "Dữ liệu gửi lên không hợp lệ.");
    }

    if (body?.action === "fetch_job") {
      const url = String((body.input as Record<string, unknown>)?.url ?? "");
      try {
        const text = await (deps.fetchJob ?? fetchJobPostingText)(url);
        log({ action: "fetch_job", status: 200 });
        return json({ result: { text } });
      } catch (failure) {
        const code = failure instanceof JobFetchError
          ? failure.code
          : "unreachable";
        log({ action: "fetch_job", status: 422, reason: code });
        return error(
          422,
          "invalid_input",
          code === "invalid_url" || code === "blocked_redirect"
            ? "Link không hợp lệ."
            : "Không đọc được trang này. Hãy dán nội dung tin tuyển dụng.",
        );
      }
    }

    if (body?.action === "quota") {
      try {
        return json({ quota: await quotaStore.current() });
      } catch (_) {
        return error(
          503,
          "quota_unavailable",
          "Chưa xem được số lượt còn lại.",
        );
      }
    }

    const actionName = String(body?.action ?? "");
    const action = actions[actionName];
    if (!action) {
      return error(400, "invalid_input", "Chức năng không tồn tại.");
    }
    const input = action.validate(body.input);
    if (!input) {
      return error(
        422,
        "invalid_input",
        "Nội dung chưa đủ hoặc vượt giới hạn cho chức năng này.",
      );
    }

    let quota: Quota;
    try {
      quota = await quotaStore.consume(action.cost);
    } catch (_) {
      return error(
        503,
        "quota_unavailable",
        "Chưa kiểm tra được số lượt. Hãy thử lại.",
      );
    }
    if (quota.allowed === false) {
      return error(
        402,
        "quota_exceeded",
        quota.plan === "pro"
          ? "Bạn đã hết lượt hôm nay. Ngày mai sẽ có lượt mới."
          : "Bạn đã hết lượt hôm nay. Nâng cấp Pro để có thêm lượt.",
        { quota },
      );
    }

    const started = Date.now();
    try {
      const completion = await deps.complete(action.buildMessages(input), {
        ...action.options,
        accept: (text: string) => action.parse(text, input) !== null,
      });
      const result = action.parse(completion.text, input);
      if (!result) throw new ProviderError("UNPARSEABLE");
      log({
        action: actionName,
        status: 200,
        model: completion.model,
        ms: Date.now() - started,
      });
      const { allowed: _allowed, ...publicQuota } = quota;
      return json({ result, quota: publicQuota, model: completion.model });
    } catch (failure) {
      await quotaStore.refund(action.cost).catch(() => {});
      log({
        action: actionName,
        status: 503,
        reason: failure instanceof Error ? failure.message : "UNKNOWN",
        ms: Date.now() - started,
      });
      return error(
        503,
        "provider_unavailable",
        "Hệ thống đang bận. Lượt dùng đã được hoàn lại, hãy thử lại sau.",
      );
    }
  };
}
