// Phase 3 — Rappels événements J-7, J-3, J-1
// Déployer : supabase functions deploy event-reminders
// Secret requis : CRON_SECRET (Dashboard → Edge Functions → Secrets), envoyé par le
// planificateur dans l'en-tête `x-cron-secret` (SEC-010). Voir docs/BETA_LAUNCH.md.

import { createHandler } from "./auth.ts";
import { sendEventReminders } from "./reminders.ts";

Deno.serve(createHandler({
  secret: Deno.env.get("CRON_SECRET"),
  sendReminders: () =>
    sendEventReminders(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    ),
}));
