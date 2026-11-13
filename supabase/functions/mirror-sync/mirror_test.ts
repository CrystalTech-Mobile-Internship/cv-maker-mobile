import {
  contentKey,
  type CvSnapshot,
  type Deletion,
  runMirrorPass,
  type SourceStore,
  type TargetStore,
} from "./mirror.ts";

function assertEquals(actual: unknown, expected: unknown, message = "") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected ${e}\nactual   ${a}`);
}

function cv(
  id: string,
  userId: string,
  updatedAt: string,
  title = "CV",
): CvSnapshot {
  return {
    id,
    user_id: userId,
    title,
    template_id: "harvard_ats",
    primary_color: "#1E293B",
    font_size_scale: 1,
    summary: "s",
    personal_info: { full_name: "A" },
    layout_settings: {},
    created_at: "2026-01-01T00:00:00Z",
    updated_at: updatedAt,
    sections: [{
      section_type: "skills",
      title: "Kỹ năng",
      order_index: 0,
      is_visible: true,
      items: [{
        item_type: "skills",
        payload: { name: "Dart", id: "x" },
        order_index: 0,
      }],
    }],
  };
}

/** In-memory project that can act as source and target. */
class Project {
  cvs = new Map<string, CvSnapshot>();
  deletionsLog: Deletion[] = [];
  users = new Map<string, string>(); // id -> email
  checkpoints = new Map<string, string>();
  userMap = new Map<string, string>();
  writes = 0;
  failOn?: string;

  source(): SourceStore {
    return {
      getCheckpoint: (kind) =>
        Promise.resolve(this.checkpoints.get(kind) ?? "1970-01-01T00:00:00Z"),
      setCheckpoint: (kind, value) => {
        this.checkpoints.set(kind, value);
        return Promise.resolve();
      },
      changedCvs: (since) =>
        Promise.resolve(
          [...this.cvs.values()]
            .filter((c) => c.updated_at > since)
            .sort((a, b) => a.updated_at.localeCompare(b.updated_at)),
        ),
      deletions: (since) =>
        Promise.resolve(this.deletionsLog.filter((d) => d.deleted_at > since)),
      userEmail: (id) => Promise.resolve(this.users.get(id) ?? null),
      mappedUser: (id) => Promise.resolve(this.userMap.get(id) ?? null),
      saveMappedUser: (s, t) => {
        this.userMap.set(s, t);
        return Promise.resolve();
      },
    };
  }

  target(clock: () => string): TargetStore {
    return {
      findUserByEmail: (email) =>
        Promise.resolve(
          [...this.users.entries()].find(([, e]) => e === email)?.[0] ?? null,
        ),
      createUser: (email) => {
        const id = `t-${this.users.size + 1}`;
        this.users.set(id, email);
        return Promise.resolve(id);
      },
      getCv: (id) => Promise.resolve(this.cvs.get(id) ?? null),
      upsertCv: (snapshot) => {
        if (this.failOn === snapshot.id) {
          return Promise.reject(new Error("boom"));
        }
        this.writes++;
        // Like the real trigger/default: the write gets the server time.
        this.cvs.set(snapshot.id, { ...snapshot, updated_at: clock() });
        return Promise.resolve();
      },
      deleteCv: (id) => {
        this.cvs.delete(id);
        this.deletionsLog.push({
          cv_id: id,
          user_id: "?",
          deleted_at: clock(),
        });
        return Promise.resolve();
      },
    };
  }
}

Deno.test("pushes new CVs and maps users by email", async () => {
  const a = new Project();
  const b = new Project();
  a.users.set("ua", "anh@example.com");
  a.cvs.set("cv1", cv("cv1", "ua", "2026-11-01T00:00:00Z"));

  const report = await runMirrorPass(
    a.source(),
    b.target(() => "2026-11-01T00:00:05Z"),
  );

  assertEquals(report.pushed, 1);
  const copy = b.cvs.get("cv1")!;
  assertEquals(b.users.get(copy.user_id), "anh@example.com");
  assertEquals(a.checkpoints.get("cvs"), "2026-11-01T00:00:00Z");
});

Deno.test("two-way passes converge without ping-pong", async () => {
  const a = new Project();
  const b = new Project();
  a.users.set("ua", "anh@example.com");
  a.cvs.set("cv1", cv("cv1", "ua", "2026-11-01T00:00:00Z"));
  let tick = 10;
  const clock = () => `2026-11-01T00:00:${String(tick++).padStart(2, "0")}Z`;

  await runMirrorPass(a.source(), b.target(clock)); // A -> B
  const back = await runMirrorPass(b.source(), a.target(clock)); // B -> A (echo)
  const again = await runMirrorPass(a.source(), b.target(clock)); // nothing new

  assertEquals(back.unchanged, 1, "echo must be skipped");
  assertEquals(a.writes, 0, "source must not be rewritten by its own echo");
  assertEquals(again.pushed, 0);
});

Deno.test("keeps the newer copy on conflict", async () => {
  const a = new Project();
  const b = new Project();
  a.users.set("ua", "anh@example.com");
  b.users.set("ub", "anh@example.com");
  a.cvs.set("cv1", cv("cv1", "ua", "2026-11-01T00:00:00Z", "Old title"));
  b.cvs.set("cv1", cv("cv1", "ub", "2026-11-02T00:00:00Z", "New title"));

  const report = await runMirrorPass(
    a.source(),
    b.target(() => "2026-11-03T00:00:00Z"),
  );

  assertEquals(report.skippedNewer, 1);
  assertEquals(b.cvs.get("cv1")!.title, "New title");
});

Deno.test("replicates deletions unless the target was edited later", async () => {
  const a = new Project();
  const b = new Project();
  b.cvs.set("gone", cv("gone", "ub", "2026-11-01T00:00:00Z"));
  b.cvs.set("kept", cv("kept", "ub", "2026-11-05T00:00:00Z"));
  a.deletionsLog.push(
    { cv_id: "gone", user_id: "ua", deleted_at: "2026-11-02T00:00:00Z" },
    { cv_id: "kept", user_id: "ua", deleted_at: "2026-11-03T00:00:00Z" },
  );

  const report = await runMirrorPass(
    a.source(),
    b.target(() => "2026-11-06T00:00:00Z"),
  );

  assertEquals(report.deleted, 1);
  assertEquals(b.cvs.has("gone"), false);
  assertEquals(b.cvs.has("kept"), true);
});

Deno.test("stops at a failing row and retries it next time", async () => {
  const a = new Project();
  const b = new Project();
  a.users.set("ua", "anh@example.com");
  a.cvs.set("cv1", cv("cv1", "ua", "2026-11-01T00:00:00Z"));
  a.cvs.set("cv2", cv("cv2", "ua", "2026-11-02T00:00:00Z"));
  b.failOn = "cv2";

  const first = await runMirrorPass(
    a.source(),
    b.target(() => "2026-11-03T00:00:00Z"),
  );
  assertEquals(first.failed, 1);
  assertEquals(a.checkpoints.get("cvs"), "2026-11-01T00:00:00Z");

  b.failOn = undefined;
  const second = await runMirrorPass(
    a.source(),
    b.target(() => "2026-11-04T00:00:00Z"),
  );
  assertEquals(second.pushed, 1);
  assertEquals(b.cvs.has("cv2"), true);
});

Deno.test("skips accounts without a verified email", async () => {
  const a = new Project();
  a.cvs.set("cv1", cv("cv1", "ghost", "2026-11-01T00:00:00Z"));
  const report = await runMirrorPass(
    a.source(),
    new Project().target(() => "x"),
  );
  assertEquals(report.skippedNoEmail, 1);
});

Deno.test("content key ignores ids, owners and timestamps", () => {
  const one = cv("cv1", "u1", "2026-01-01T00:00:00Z");
  const two = { ...cv("cv1", "u2", "2026-02-01T00:00:00Z") };
  two.sections[0].items[0].payload = { id: "other", name: "Dart" };
  assertEquals(contentKey(one), contentKey(two));
});
