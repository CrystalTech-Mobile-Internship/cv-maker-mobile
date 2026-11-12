// One-directional replication pass: pushes CV changes and deletions from the
// project this function runs on (source) to the other project (target).
// Deploy on both projects (each pointing at the other) for two-way sync.
//
// Loop prevention: a CV is only written when its content differs from the
// target copy, so the echo of a mirrored write is a no-op on the way back.
// Conflicts: the copy with the later `updated_at` wins.

export type CvItem = {
  item_type: string;
  payload: Record<string, unknown>;
  order_index: number;
};

export type CvSection = {
  section_type: string;
  title: string;
  order_index: number;
  is_visible: boolean;
  items: CvItem[];
};

export type CvSnapshot = {
  id: string;
  user_id: string;
  title: string;
  template_id: string | null;
  primary_color: string;
  font_size_scale: number;
  summary: string | null;
  personal_info: Record<string, unknown>;
  layout_settings: Record<string, unknown>;
  created_at: string;
  updated_at: string;
  sections: CvSection[];
};

export type Deletion = { cv_id: string; user_id: string; deleted_at: string };

export type SourceStore = {
  getCheckpoint(kind: "cvs" | "deletions"): Promise<string>;
  setCheckpoint(kind: "cvs" | "deletions", value: string): Promise<void>;
  changedCvs(since: string, limit: number): Promise<CvSnapshot[]>;
  deletions(since: string, limit: number): Promise<Deletion[]>;
  userEmail(userId: string): Promise<string | null>;
  mappedUser(sourceUserId: string): Promise<string | null>;
  saveMappedUser(
    sourceUserId: string,
    targetUserId: string,
    email: string,
  ): Promise<void>;
};

export type TargetStore = {
  findUserByEmail(email: string): Promise<string | null>;
  createUser(email: string): Promise<string>;
  getCv(id: string): Promise<CvSnapshot | null>;
  upsertCv(cv: CvSnapshot): Promise<void>;
  deleteCv(id: string): Promise<void>;
};

export type MirrorReport = {
  pushed: number;
  unchanged: number;
  skippedNewer: number;
  skippedNoEmail: number;
  deleted: number;
  failed: number;
};

/** Content fingerprint that ignores ids, owners and timestamps. */
export function contentKey(cv: CvSnapshot): string {
  const sortKeys = (value: unknown): unknown => {
    if (Array.isArray(value)) return value.map(sortKeys);
    if (value && typeof value === "object") {
      return Object.fromEntries(
        Object.keys(value as Record<string, unknown>)
          .filter((key) => key !== "id")
          .sort()
          .map((key) => [
            key,
            sortKeys((value as Record<string, unknown>)[key]),
          ]),
      );
    }
    return value;
  };
  return JSON.stringify(
    sortKeys({
      title: cv.title,
      template_id: cv.template_id,
      primary_color: cv.primary_color,
      font_size_scale: Number(cv.font_size_scale),
      summary: cv.summary ?? "",
      personal_info: cv.personal_info ?? {},
      layout_settings: cv.layout_settings ?? {},
      sections: [...cv.sections]
        .sort((a, b) => a.order_index - b.order_index)
        .map((section) => ({
          section_type: section.section_type,
          title: section.title,
          is_visible: section.is_visible,
          items: [...section.items]
            .sort((a, b) => a.order_index - b.order_index)
            .map((item) => ({
              item_type: item.item_type,
              payload: item.payload,
            })),
        })),
    }),
  );
}

async function resolveUser(
  source: SourceStore,
  target: TargetStore,
  sourceUserId: string,
): Promise<string | null> {
  const cached = await source.mappedUser(sourceUserId);
  if (cached) return cached;
  const email = await source.userEmail(sourceUserId);
  if (!email) return null;
  const targetUserId = (await target.findUserByEmail(email)) ??
    (await target.createUser(email));
  await source.saveMappedUser(sourceUserId, targetUserId, email);
  return targetUserId;
}

export async function runMirrorPass(
  source: SourceStore,
  target: TargetStore,
  batchSize = 100,
): Promise<MirrorReport> {
  const report: MirrorReport = {
    pushed: 0,
    unchanged: 0,
    skippedNewer: 0,
    skippedNoEmail: 0,
    deleted: 0,
    failed: 0,
  };

  // CV upserts, oldest change first so the checkpoint only moves forward
  // past rows that were handled.
  const cvSince = await source.getCheckpoint("cvs");
  const changed = await source.changedCvs(cvSince, batchSize);
  let cvCheckpoint = cvSince;
  for (const cv of changed) {
    try {
      const targetUserId = await resolveUser(source, target, cv.user_id);
      if (!targetUserId) {
        report.skippedNoEmail++;
      } else {
        const existing = await target.getCv(cv.id);
        const mirrored = { ...cv, user_id: targetUserId };
        if (existing && contentKey(existing) === contentKey(mirrored)) {
          report.unchanged++;
        } else if (
          existing &&
          Date.parse(existing.updated_at) > Date.parse(cv.updated_at)
        ) {
          report.skippedNewer++;
        } else {
          await target.upsertCv(mirrored);
          report.pushed++;
        }
      }
      cvCheckpoint = cv.updated_at;
    } catch (_) {
      report.failed++;
      break; // retry from this row on the next run
    }
  }
  if (cvCheckpoint !== cvSince) await source.setCheckpoint("cvs", cvCheckpoint);

  const delSince = await source.getCheckpoint("deletions");
  const deletions = await source.deletions(delSince, batchSize);
  let delCheckpoint = delSince;
  for (const deletion of deletions) {
    try {
      const existing = await target.getCv(deletion.cv_id);
      if (
        existing &&
        Date.parse(existing.updated_at) <= Date.parse(deletion.deleted_at)
      ) {
        await target.deleteCv(deletion.cv_id);
        report.deleted++;
      }
      delCheckpoint = deletion.deleted_at;
    } catch (_) {
      report.failed++;
      break;
    }
  }
  if (delCheckpoint !== delSince) {
    await source.setCheckpoint("deletions", delCheckpoint);
  }

  return report;
}
