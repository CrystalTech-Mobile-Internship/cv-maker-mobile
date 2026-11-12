// Supabase-backed implementations of the mirror stores (service role).

import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

import type {
  CvSection,
  CvSnapshot,
  Deletion,
  SourceStore,
  TargetStore,
} from "./mirror.ts";

const cvColumns =
  "id, user_id, title, template_id, primary_color, font_size_scale, summary, personal_info, layout_settings, created_at, updated_at, cv_sections(section_type, title, order_index, is_visible, cv_items(item_type, payload, order_index))";

type Row = Record<string, unknown>;

function toSnapshot(row: Row): CvSnapshot {
  const sections = (row.cv_sections as Row[] | null) ?? [];
  return {
    id: String(row.id),
    user_id: String(row.user_id),
    title: String(row.title ?? ""),
    template_id: (row.template_id as string | null) ?? null,
    primary_color: String(row.primary_color ?? "#1E293B"),
    font_size_scale: Number(row.font_size_scale ?? 1),
    summary: (row.summary as string | null) ?? null,
    personal_info: (row.personal_info as Record<string, unknown>) ?? {},
    layout_settings: (row.layout_settings as Record<string, unknown>) ?? {},
    created_at: String(row.created_at),
    updated_at: String(row.updated_at),
    sections: sections.map((section): CvSection => ({
      section_type: String(section.section_type),
      title: String(section.title ?? ""),
      order_index: Number(section.order_index ?? 0),
      is_visible: section.is_visible !== false,
      items: ((section.cv_items as Row[] | null) ?? []).map((item) => ({
        item_type: String(item.item_type),
        payload: (item.payload as Record<string, unknown>) ?? {},
        order_index: Number(item.order_index ?? 0),
      })),
    })),
  };
}

function check<T>(result: { data: T; error: unknown }): T {
  if (result.error) {
    const message = (result.error as { message?: string }).message ?? "error";
    throw new Error(message);
  }
  return result.data;
}

export function supabaseSource(
  client: SupabaseClient,
  targetName: string,
): SourceStore {
  return {
    async getCheckpoint(kind) {
      const data = check(
        await client
          .from("mirror_checkpoints")
          .select("last_synced_at")
          .eq("target", targetName)
          .eq("kind", kind)
          .maybeSingle(),
      ) as Row | null;
      return data ? String(data.last_synced_at) : "1970-01-01T00:00:00Z";
    },
    async setCheckpoint(kind, value) {
      check(
        await client.from("mirror_checkpoints").upsert({
          target: targetName,
          kind,
          last_synced_at: value,
          updated_at: new Date().toISOString(),
        }),
      );
    },
    async changedCvs(since, limit) {
      const rows = check(
        await client
          .from("cvs")
          .select(cvColumns)
          .gt("updated_at", since)
          .order("updated_at", { ascending: true })
          .limit(limit),
      ) as Row[];
      return rows.map(toSnapshot);
    },
    async deletions(since, limit) {
      return check(
        await client
          .from("cv_deletions")
          .select("cv_id, user_id, deleted_at")
          .gt("deleted_at", since)
          .order("deleted_at", { ascending: true })
          .limit(limit),
      ) as Deletion[];
    },
    async userEmail(userId) {
      const { data, error } = await client.auth.admin.getUserById(userId);
      if (error || !data.user?.email) return null;
      // Only replicate accounts whose email is verified.
      if (!data.user.email_confirmed_at) return null;
      return data.user.email;
    },
    async mappedUser(sourceUserId) {
      const data = check(
        await client
          .from("mirror_user_map")
          .select("target_user_id")
          .eq("target", targetName)
          .eq("source_user_id", sourceUserId)
          .maybeSingle(),
      ) as Row | null;
      return data ? String(data.target_user_id) : null;
    },
    async saveMappedUser(sourceUserId, targetUserId, email) {
      check(
        await client.from("mirror_user_map").upsert({
          target: targetName,
          source_user_id: sourceUserId,
          target_user_id: targetUserId,
          email,
        }),
      );
    },
  };
}

export function supabaseTarget(client: SupabaseClient): TargetStore {
  return {
    async findUserByEmail(email) {
      const data = check(
        await client.rpc("mirror_find_user_id", { p_email: email }),
      );
      return (data as string | null) ?? null;
    },
    async createUser(email) {
      // No password is set: the user signs in with Google or resets the
      // password on the mirror project. The email is already verified on
      // the source project.
      const { data, error } = await client.auth.admin.createUser({
        email,
        email_confirm: true,
        user_metadata: { mirrored: true },
      });
      if (error || !data.user) throw new Error("CREATE_USER_FAILED");
      return data.user.id;
    },
    async getCv(id) {
      const data = check(
        await client.from("cvs").select(cvColumns).eq("id", id).maybeSingle(),
      ) as Row | null;
      return data ? toSnapshot(data) : null;
    },
    async upsertCv(cv) {
      const { sections, ...row } = cv;
      check(await client.from("cvs").upsert(row));
      check(await client.from("cv_sections").delete().eq("cv_id", cv.id));
      for (const section of sections) {
        const inserted = check(
          await client
            .from("cv_sections")
            .insert({
              cv_id: cv.id,
              section_type: section.section_type,
              title: section.title,
              order_index: section.order_index,
              is_visible: section.is_visible,
            })
            .select("id")
            .single(),
        ) as Row;
        if (!section.items.length) continue;
        check(
          await client.from("cv_items").insert(
            section.items.map((item) => ({
              cv_id: cv.id,
              section_id: inserted.id,
              item_type: item.item_type,
              payload: item.payload,
              order_index: item.order_index,
            })),
          ),
        );
      }
    },
    async deleteCv(id) {
      check(await client.from("cvs").delete().eq("id", id));
    },
  };
}
