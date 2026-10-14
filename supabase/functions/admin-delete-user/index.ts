// SEC-023 — Suppression d'un compte (auth.users) par un administrateur.
// Déployer : supabase functions deploy admin-delete-user
// Appel : POST { "user_id": "<uuid>" } avec le JWT de l'administrateur (supabase.functions.invoke).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHandler, refusalFromPostgres } from "./handler.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

Deno.serve(createHandler({
  async authorize(authorization, target) {
    // Client à l'identité de l'appelant : auth.uid() vaut son id dans check_member_deletion.
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { error } = await caller.rpc("check_member_deletion", { target });
    return refusalFromPostgres(error);
  },
  async listObjects(target) {
    const { data, error } = await admin.rpc("member_storage_objects", { target });
    if (error) throw error;
    return (data ?? []) as { bucket_id: string; name: string }[];
  },
  async removeObjects(bucket, names) {
    const { error } = await admin.storage.from(bucket).remove(names);
    if (error) throw error;
  },
  async deleteUser(target) {
    const { error } = await admin.auth.admin.deleteUser(target);
    if (error) throw error;
  },
}));
