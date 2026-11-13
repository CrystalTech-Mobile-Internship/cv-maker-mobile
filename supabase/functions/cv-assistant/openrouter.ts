// OpenRouter client with an ordered model fallback list.
// The API key is read from the function environment only.

export type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

export type CompletionOptions = {
  maxTokens: number;
  temperature: number;
  json: boolean;
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

export class ProviderError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ProviderError";
  }
}

export function configuredModels(env: (name: string) => string | undefined) {
  const raw = env("OPENROUTER_MODELS") ?? "";
  const models = raw
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  return models.length ? models : defaultModels;
}

export function createOpenRouterComplete(
  env: (name: string) => string | undefined,
  fetchImpl: typeof fetch = fetch,
  timeoutMs = 45_000,
): CompleteFn {
  return async (messages, options) => {
    const apiKey = env("OPENROUTER_API_KEY");
    if (!apiKey) throw new ProviderError("OPENROUTER_NOT_CONFIGURED");

    const models = configuredModels(env);
    let lastError = "NO_MODEL";
    for (const model of models) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      try {
        const response = await fetchImpl(
          "https://openrouter.ai/api/v1/chat/completions",
          {
            method: "POST",
            signal: controller.signal,
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${apiKey}`,
              "X-Title": "Smart CV Maker",
            },
            body: JSON.stringify({
              model,
              messages,
              temperature: options.temperature,
              max_tokens: options.maxTokens,
              reasoning: { effort: "low", exclude: true },
              ...(options.json
                ? { response_format: { type: "json_object" } }
                : {}),
            }),
          },
        );
        if (!response.ok) {
          lastError = `HTTP_${response.status}`;
          await response.body?.cancel();
          continue;
        }
        const data = await response.json();
        const text = String(data?.choices?.[0]?.message?.content ?? "").trim();
        if (!text) {
          lastError = "EMPTY";
          continue;
        }
        return { text, model };
      } catch (error) {
        lastError = error instanceof Error ? error.name : "FETCH_FAILED";
      } finally {
        clearTimeout(timer);
      }
    }
    throw new ProviderError(lastError);
  };
}
