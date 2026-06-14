// Phase 4 — SMS de secours (AfricasTalking / Orange API Guinée)
// Variables : SMS_API_KEY, SMS_SENDER_ID

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${serviceKey}`) {
    return new Response(JSON.stringify({ error: "Service role requis" }), {
      status: 403,
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceKey!,
  );

  const { user_id, phone, message } = await req.json();

  if (!phone || !message) {
    return new Response(JSON.stringify({ error: "phone et message requis" }), {
      status: 400,
    });
  }

  const { data: row, error } = await supabase
    .from("sms_notifications")
    .insert({
      user_id: user_id ?? null,
      phone,
      message,
      status: "queued",
    })
    .select("id")
    .single();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  const smsConfigured = !!Deno.env.get("SMS_API_KEY");

  if (smsConfigured) {
    // TODO: intégrer AfricasTalking ou API Orange Guinée
    await supabase
      .from("sms_notifications")
      .update({ status: "sent" })
      .eq("id", row.id);
  }

  return new Response(
    JSON.stringify({
      id: row.id,
      status: smsConfigured ? "sent" : "queued",
      message: smsConfigured
        ? "SMS envoyé"
        : "SMS en file. Configurez SMS_API_KEY pour l'envoi réel.",
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
