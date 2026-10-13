// Rappels événements J-7, J-3, J-1 et jour J (logique inchangée par SEC-010 ; la
// déduplication, la planification et les performances relèvent de REL-005).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const offsets = [7, 3, 1, 0] as const;

export async function sendEventReminders(
  supabaseUrl: string,
  serviceRoleKey: string,
): Promise<{ notifications: number }> {
  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const today = new Date();
  let created = 0;

  for (const days of offsets) {
    const target = new Date(today);
    target.setDate(target.getDate() + days);
    const dayStart = target.toISOString().split("T")[0];

    const { data: events, error } = await supabase
      .from("events")
      .select("id, title, starts_at")
      .gte("starts_at", `${dayStart}T00:00:00`)
      .lt("starts_at", `${dayStart}T23:59:59`);

    if (error) throw error;

    for (const event of events ?? []) {
      const label = days === 0 ? "aujourd'hui" : `dans ${days} jour(s)`;
      const { data: rsvps } = await supabase
        .from("event_rsvps")
        .select("user_id")
        .eq("event_id", event.id)
        .eq("status", "going");

      for (const rsvp of rsvps ?? []) {
        const { data: prefs } = await supabase
          .from("notification_preferences")
          .select("events_enabled")
          .eq("user_id", rsvp.user_id)
          .maybeSingle();

        if (prefs && prefs.events_enabled === false) continue;

        const { error: insertError } = await supabase
          .from("notifications")
          .insert({
            user_id: rsvp.user_id,
            title: `Rappel : ${event.title}`,
            body: `L'événement a lieu ${label}.`,
            category: "events",
          });

        if (!insertError) created++;
      }
    }
  }

  return { notifications: created };
}
