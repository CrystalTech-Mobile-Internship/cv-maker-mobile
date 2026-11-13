// Fetches a public job posting page and returns its readable text.
// Guards against SSRF: only http(s) on default ports, no IP literals or
// local hostnames, redirects re-checked, bounded size and time.

export class JobFetchError extends Error {
  constructor(public readonly code: string) {
    super(code);
  }
}

const maxBytes = 1_500_000;
const maxRedirects = 3;
const timeoutMs = 10_000;

export function isAllowedJobUrl(raw: string): URL | null {
  let url: URL;
  try {
    url = new URL(raw.trim());
  } catch (_) {
    return null;
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") return null;
  if (url.username || url.password) return null;
  if (url.port && url.port !== "80" && url.port !== "443") return null;
  const host = url.hostname.toLowerCase();
  if (!host.includes(".")) return null;
  if (/^[\d.]+$/.test(host) || host.includes(":") || host.startsWith("[")) {
    return null; // IPv4/IPv6 literals
  }
  if (
    host === "localhost" ||
    host.endsWith(".localhost") ||
    host.endsWith(".local") ||
    host.endsWith(".internal") ||
    host.endsWith(".lan") ||
    host.endsWith(".supabase.co") ||
    host.endsWith(".supabase.in")
  ) {
    return null;
  }
  return url;
}

const entities: Record<string, string> = {
  "&nbsp;": " ",
  "&amp;": "&",
  "&lt;": "<",
  "&gt;": ">",
  "&quot;": '"',
  "&#39;": "'",
  "&apos;": "'",
};

/** Converts HTML to plain text, keeping line breaks between blocks. */
export function htmlToText(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<svg[\s\S]*?<\/svg>/gi, " ")
    .replace(/<(br|\/p|\/div|\/li|\/h[1-6]|\/tr)[^>]*>/gi, "\n")
    .replace(/<li[^>]*>/gi, "\n- ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&[a-z#0-9]+;/gi, (entity) => {
      if (entities[entity]) return entities[entity];
      const code = entity.match(/^&#(\d+);$/);
      return code ? String.fromCharCode(Number(code[1])) : " ";
    })
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\s*\n\s*/g, "\n")
    .split("\n")
    .filter((line) => line.replace(/[-•*|\s]/g, "").length > 1)
    .join("\n")
    .trim();
}

function asText(value: unknown): string {
  if (typeof value === "string") return value;
  if (Array.isArray(value)) {
    return value.filter((v) => typeof v === "string").join(", ");
  }
  return "";
}

/** Job details published as schema.org JobPosting (used by most job boards). */
export function extractJobPosting(html: string): string | null {
  const pattern =
    /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  for (const block of html.matchAll(pattern)) {
    let data: unknown;
    try {
      data = JSON.parse(block[1].trim());
    } catch (_) {
      continue;
    }
    const queue: unknown[] = [data];
    while (queue.length) {
      const item = queue.shift();
      if (Array.isArray(item)) {
        queue.push(...item);
        continue;
      }
      if (!item || typeof item !== "object") continue;
      const record = item as Record<string, unknown>;
      if (record["@graph"]) queue.push(record["@graph"]);
      const type = record["@type"];
      const isJob = type === "JobPosting" ||
        (Array.isArray(type) && type.includes("JobPosting"));
      if (!isJob) continue;
      const text = [
        record.title,
        record.description,
        record.qualifications,
        record.skills,
        record.experienceRequirements,
        record.responsibilities,
      ]
        .map(asText)
        .filter(Boolean)
        .map(htmlToText)
        .join("\n")
        .trim();
      if (text.length >= 80) return text;
    }
  }
  return null;
}

/** Prefers the page's main content area over navigation and footers. */
export function mainContent(html: string): string {
  const main = html.match(/<main[\s\S]*?<\/main>/i) ??
    html.match(/<article[\s\S]*?<\/article>/i);
  return htmlToText(main ? main[0] : html);
}

async function readLimited(response: Response): Promise<string> {
  const reader = response.body?.getReader();
  if (!reader) throw new JobFetchError("empty");
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (total < maxBytes) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    total += value.length;
  }
  if (total >= maxBytes) await reader.cancel();
  const bytes = new Uint8Array(Math.min(total, maxBytes));
  let offset = 0;
  for (const chunk of chunks) {
    const slice = chunk.subarray(0, bytes.length - offset);
    bytes.set(slice, offset);
    offset += slice.length;
    if (offset >= bytes.length) break;
  }
  return new TextDecoder().decode(bytes);
}

export async function fetchJobPostingText(
  raw: string,
  fetchImpl: typeof fetch = fetch,
): Promise<string> {
  const first = isAllowedJobUrl(raw);
  if (!first) throw new JobFetchError("invalid_url");
  let url: URL = first;

  for (let hop = 0; hop <= maxRedirects; hop++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      let response: Response;
      try {
        response = await fetchImpl(url.toString(), {
          redirect: "manual",
          signal: controller.signal,
          headers: {
            "User-Agent": "Mozilla/5.0 (compatible; SmartCVMaker/1.0)",
            "Accept": "text/html,application/xhtml+xml",
            "Accept-Language": "vi,en;q=0.8",
          },
        });
      } catch (_) {
        throw new JobFetchError("unreachable");
      }
      if (response.status >= 300 && response.status < 400) {
        const location = response.headers.get("location");
        await response.body?.cancel();
        const next: URL | null = location
          ? isAllowedJobUrl(new URL(location, url).toString())
          : null;
        if (!next) throw new JobFetchError("blocked_redirect");
        url = next;
        continue;
      }
      if (!response.ok) {
        await response.body?.cancel();
        throw new JobFetchError("http_error");
      }
      const type = response.headers.get("content-type") ?? "";
      if (!type.includes("html") && !type.includes("text")) {
        await response.body?.cancel();
        throw new JobFetchError("not_html");
      }
      const html = await readLimited(response);
      const text = extractJobPosting(html) ?? mainContent(html);
      if (text.length < 80) throw new JobFetchError("empty");
      return text.slice(0, 12_000);
    } finally {
      clearTimeout(timer);
    }
  }
  throw new JobFetchError("blocked_redirect");
}
