// SEC-023 — Suppression d'un compte par un administrateur.
//
// L'autorisation est décidée en base par public.check_member_deletion(), appelée avec le JWT
// de l'appelant (mêmes règles que set_member_role, ADR-0008). Si elle passe, la fonction
// supprime avec le service role les fichiers déposés par le membre, puis auth.users : le
// profil et les données personnelles suivent en cascade, les contenus collectifs sont
// conservés sans auteur (cf. migration 20261014100000_sec023_suppression_compte.sql).

export type Refusal = { status: 401 | 403 | 404 | 500; error: string };

export interface Dependencies {
  /** Vérifie les droits de l'appelant (JWT) sur la cible ; null si la suppression est permise. */
  authorize(authorization: string, target: string): Promise<Refusal | null>;
  /** Fichiers Storage déposés par le membre. */
  listObjects(target: string): Promise<{ bucket_id: string; name: string }[]>;
  removeObjects(bucket: string, names: string[]): Promise<void>;
  deleteUser(target: string): Promise<void>;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return Response.json(body, { status, headers: corsHeaders });
}

/** Correspondance entre les codes d'erreur SQL de check_member_deletion et HTTP. */
export function refusalFromPostgres(
  error: { code?: string; message?: string } | null,
): Refusal | null {
  if (!error) return null;
  switch (error.code) {
    case "42501":
      return { status: 403, error: error.message ?? "Action refusée" };
    case "P0002":
      return { status: 404, error: "Membre introuvable" };
    case "PGRST301":
      return { status: 401, error: "Session invalide" };
    default:
      return { status: 500, error: "Vérification des droits impossible" };
  }
}

export function createHandler(deps: Dependencies): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const authorization = req.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return json({ error: "Non autorisé" }, 401);

    let target: unknown;
    try {
      target = (await req.json())?.user_id;
    } catch (_) {
      target = undefined;
    }
    if (typeof target !== "string" || !UUID.test(target)) {
      return json({ error: "user_id invalide" }, 400);
    }

    const refusal = await deps.authorize(authorization, target);
    if (refusal) return json({ error: refusal.error }, refusal.status);

    try {
      const objects = await deps.listObjects(target);
      const byBucket = new Map<string, string[]>();
      for (const o of objects) {
        byBucket.set(o.bucket_id, [...(byBucket.get(o.bucket_id) ?? []), o.name]);
      }
      for (const [bucket, names] of byBucket) {
        await deps.removeObjects(bucket, names);
      }
      await deps.deleteUser(target);
      return json({ ok: true, files: objects.length });
    } catch (_) {
      // Pas de détail interne renvoyé à l'appelant.
      return json({ error: "Échec de la suppression du compte" }, 500);
    }
  };
}
