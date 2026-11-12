import {
  extractJobPosting,
  fetchJobPostingText,
  htmlToText,
  isAllowedJobUrl,
} from "./job_fetch.ts";

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("rejects local, private and non-web URLs", () => {
  for (
    const url of [
      "http://localhost/x",
      "http://127.0.0.1/x",
      "http://[::1]/x",
      "http://10.0.0.5/x",
      "ftp://example.com/x",
      "http://example.com:8080/x",
      "http://user:pw@example.com/x",
      "http://intranet/x",
      "https://abc.supabase.co/rest/v1",
    ]
  ) {
    assert(isAllowedJobUrl(url) === null, `should reject ${url}`);
  }
  assert(
    isAllowedJobUrl("https://www.topcv.vn/viec-lam/abc") !== null,
    "public url",
  );
});

Deno.test("turns job HTML into readable text", () => {
  const text = htmlToText(
    "<html><script>var x=1</script><h1>Flutter Dev</h1><ul><li>Dart</li><li>Riverpod &amp; Git</li></ul></html>",
  );
  assert(text.includes("Flutter Dev"), "title kept");
  assert(text.includes("- Riverpod & Git"), "list item kept");
  assert(!text.includes("var x"), "script removed");
});

Deno.test("re-checks redirects", async () => {
  const fakeFetch = ((_url: string) =>
    Promise.resolve(
      new Response(null, {
        status: 302,
        headers: { location: "http://127.0.0.1/admin" },
      }),
    )) as unknown as typeof fetch;
  let code = "";
  try {
    await fetchJobPostingText("https://jobs.example.com/a", fakeFetch);
  } catch (error) {
    code = (error as { code: string }).code;
  }
  assert(code === "blocked_redirect", `got ${code}`);
});

Deno.test("returns extracted text for a public page", async () => {
  const body = "<p>" + "Yêu cầu: Flutter, Dart, Git. ".repeat(10) + "</p>";
  const fakeFetch = (() =>
    Promise.resolve(
      new Response(body, {
        headers: { "content-type": "text/html; charset=utf-8" },
      }),
    )) as unknown as typeof fetch;
  const text = await fetchJobPostingText(
    "https://jobs.example.com/a",
    fakeFetch,
  );
  assert(text.startsWith("Yêu cầu: Flutter"), text.slice(0, 40));
});

Deno.test("prefers structured JobPosting data", () => {
  const html =
    `<nav>Cloud Docker Kubernetes</nav><script type="application/ld+json">${
      JSON.stringify({
        "@context": "https://schema.org",
        "@type": "JobPosting",
        title: "Flutter Developer",
        description:
          "<p>Yêu cầu: thành thạo Flutter, Dart, Riverpod và Git. Có kinh nghiệm làm việc với REST API.</p>",
      })
    }</script>`;
  const text = extractJobPosting(html)!;
  assert(text.includes("Flutter Developer"), "title");
  assert(text.includes("Riverpod"), "description");
  assert(!text.includes("Kubernetes"), "navigation ignored");
});
