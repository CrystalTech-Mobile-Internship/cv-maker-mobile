// AI client with an ordered fallback list across two providers:
// Google Gemini (if GEMINI_API_KEY is set) first, then OpenRouter.
// Keys are read from the function environment only.

export type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

export type CompletionOptions = {
  maxTokens: number;
  temperature: number;
  json: boolean;
  /** Wait per model; long documents need more than the default. */
  timeoutMs?: number;
  /** Rejecting a reply moves on to the next model instead of failing. */
  accept?: (text: string) => boolean;
};

export type CompletionResult = { text: string; model: string };

export type CompleteFn = (
  messages: ChatMessage[],
  options: CompletionOptions,
) => Promise<CompletionResult>;

const defaultModels = [
  "nvidia/nemotron-3.5-super-vl:free",
  "baidu/ernie-5.5-flash-preview:free",
  "google/gemma-4-31b-it:free",
  "nvidia/nemotron-3.5-lightning:free",
];

/** Used when GEMINI_API_KEY is set but GEMINI_MODELS is not. Fast models
 * first; a model the key cannot use is skipped for a while. */
const defaultGeminiModels = [
  "gemini-3.8-flash",
  "gemini-3.6-flash",
  "gemini-4-carbon",
  "gemini-3-flash-preview",
  "gemini-3.5-flash-lite",
  "gemini-3.1-flash-lite",
  "gemini-3.1-pro-preview",
  "gemini-2.5-flash-lite",
];

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions";

/** How long a model that ran out of quota is skipped, when no hint is given. */
const DEFAULT_COOLDOWN_MS = 60_000;
const MAX_COOLDOWN_MS = 10 * 60_000;

export class ProviderError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ProviderError";
  }
}

type Route = {
  provider: "gemini" | "openrouter";
  url: string;
  key: string;
  model: string;
};

function list(raw: string | undefined) {
  return (raw ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export function configuredModels(env: (name: string) => string | undefined) {
  const models = list(env("OPENROUTER_MODELS"));
  return models.length ? models : defaultModels;
}

export function configuredGeminiModels(
  env: (name: string) => string | undefined,
) {
  const models = list(env("GEMINI_MODELS"));
  return models.length ? models : defaultGeminiModels;
}

/** Every model to try, Gemini first, skipping providers without a key. */
export function configuredRoutes(
  env: (name: string) => string | undefined,
): Route[] {
  const routes: Route[] = [];
  const gemini = env("GEMINI_API_KEY")?.trim();
  if (gemini) {
    for (const model of configuredGeminiModels(env)) {
      routes.push({ provider: "gemini", url: GEMINI_URL, key: gemini, model });
    }
  }
  const openrouter = env("OPENROUTER_API_KEY")?.trim();
  if (openrouter) {
    for (const model of configuredModels(env)) {
      routes.push({
        provider: "openrouter",
        url: OPENROUTER_URL,
        key: openrouter,
        model,
      });
    }
  }
  return routes;
}

function cooldownMs(response: Response) {
  const seconds = Number(response.headers.get("retry-after"));
  if (Number.isFinite(seconds) && seconds > 0) {
    return Math.min(seconds * 1000, MAX_COOLDOWN_MS);
  }
  return DEFAULT_COOLDOWN_MS;
}

function requestBody(route: Route, messages: ChatMessage[], options: CompletionOptions) {
  return JSON.stringify({
    model: route.model,
    messages,
    temperature: options.temperature,
    max_tokens: options.maxTokens,
    // OpenRouter's switch for thinking models; Gemini does not accept it.
    ...(route.provider === "openrouter"
      ? { reasoning: { effort: "low", exclude: true } }
      : {}),
    ...(options.json ? { response_format: { type: "json_object" } } : {}),
  });
}

export function createOpenRouterComplete(
  env: (name: string) => string | undefined,
  fetchImpl: typeof fetch = fetch,
  timeoutMs = 45_000,
  // Total budget across all models, kept below the app's own wait.
  deadlineMs = 110_000,
  // Models that ran out of quota, skipped until the time stored here.
  // One map per running function instance.
  coolingUntil: Map<string, number> = new Map(),
): CompleteFn {
  return async (messages, options) => {
    const routes = configuredRoutes(env);
    if (!routes.length) throw new ProviderError("OPENROUTER_NOT_CONFIGURED");

    // Skip models that are resting after a quota error, unless every model
    // is resting, in which case try them all anyway.
    const now = Date.now();
    const ready = routes.filter(
      (route) => (coolingUntil.get(`${route.provider}:${route.model}`) ?? 0) <= now,
    );
    const order = ready.length ? ready : routes;

    let lastError = "NO_MODEL";
    const started = Date.now();
    for (const route of order) {
      const remaining = deadlineMs - (Date.now() - started);
      if (remaining < 5_000) {
        lastError = lastError === "NO_MODEL" ? "DEADLINE" : lastError;
        break;
      }
      const controller = new AbortController();
      const timer = setTimeout(
        () => controller.abort(),
        Math.min(options.timeoutMs ?? timeoutMs, remaining),
      );
      try {
        const response = await fetchImpl(route.url, {
          method: "POST",
          signal: controller.signal,
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${route.key}`,
            ...(route.provider === "openrouter"
              ? { "X-Title": "Smart CV Maker" }
              : {}),
          },
          body: requestBody(route, messages, options),
        });
        if (!response.ok) {
          lastError = `HTTP_${response.status}`;
          // 429: out of quota for now. 403/404: this key cannot use the
          // model (retired, not on the free tier). Skip it for a while.
          const rest = response.status === 429
            ? cooldownMs(response)
            : response.status === 403 || response.status === 404
            ? MAX_COOLDOWN_MS
            : 0;
          if (rest > 0) {
            coolingUntil.set(
              `${route.provider}:${route.model}`,
              Date.now() + rest,
            );
          }
          await response.body?.cancel();
          continue;
        }
        const data = await response.json();
        const text = String(data?.choices?.[0]?.message?.content ?? "").trim();
        if (!text) {
          lastError = "EMPTY";
          continue;
        }
        if (options.accept && !options.accept(text)) {
          lastError = "UNPARSEABLE";
          continue;
        }
        coolingUntil.delete(`${route.provider}:${route.model}`);
        return { text, model: route.model };
      } catch (error) {
        lastError = error instanceof Error ? error.name : "FETCH_FAILED";
      } finally {
        clearTimeout(timer);
      }
    }
    throw new ProviderError(lastError);
  };
}
