// SEC-010 — Authentification de l'appelant de event-reminders.
//
// La fonction utilise la clé service role et notifie tous les participants : elle ne doit
// être déclenchée que par le planificateur (pg_cron + pg_net, REL-005), qui envoie le secret
// partagé CRON_SECRET dans l'en-tête `x-cron-secret`. La clé anon publique (présente dans
// l'app) ne suffit pas.

export const CRON_SECRET_HEADER = "x-cron-secret";

const encoder = new TextEncoder();

/** Comparaison en temps constant (empreintes SHA-256 de longueur fixe). */
export async function secretsEqual(a: string, b: string): Promise<boolean> {
  const [da, db] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(a)),
    crypto.subtle.digest("SHA-256", encoder.encode(b)),
  ]);
  const va = new Uint8Array(da);
  const vb = new Uint8Array(db);
  let diff = 0;
  for (let i = 0; i < va.length; i++) diff |= va[i] ^ vb[i];
  return diff === 0;
}

export type Authorization =
  | { ok: true }
  | { ok: false; status: 401 | 500; error: string };

/**
 * Vérifie que la requête porte le secret attendu. Sans secret configuré, la fonction
 * refuse tout appel (500) plutôt que de s'exécuter sans contrôle.
 */
export async function authorizeCron(
  req: Request,
  expectedSecret: string | undefined,
): Promise<Authorization> {
  if (!expectedSecret) {
    return { ok: false, status: 500, error: "CRON_SECRET non configuré" };
  }
  const provided = req.headers.get(CRON_SECRET_HEADER);
  if (!provided || !(await secretsEqual(provided, expectedSecret))) {
    return { ok: false, status: 401, error: "Non autorisé" };
  }
  return { ok: true };
}

/** Point d'entrée HTTP, indépendant de Supabase pour être testé sans réseau. */
export function createHandler(
  options: {
    secret: string | undefined;
    sendReminders: () => Promise<{ notifications: number }>;
  },
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    const auth = await authorizeCron(req, options.secret);
    if (!auth.ok) {
      return Response.json({ error: auth.error }, { status: auth.status });
    }
    try {
      const { notifications } = await options.sendReminders();
      return Response.json({ ok: true, notifications });
    } catch (_) {
      // Pas de détail SQL renvoyé à l'appelant.
      return Response.json({ error: "Échec de l'envoi des rappels" }, { status: 500 });
    }
  };
}
