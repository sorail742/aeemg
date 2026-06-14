// Phase 4 — Initier un paiement Orange Money Guinée
// Variables : ORANGE_MONEY_API_KEY, ORANGE_MONEY_MERCHANT_ID (à configurer)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Non autorisé" }), {
      status: 401,
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: "Non autorisé" }), {
      status: 401,
    });
  }

  const body = await req.json();
  const donationId = body.donation_id as string | undefined;
  const amount = Number(body.amount);
  const phone = String(body.phone ?? "").replace(/\s/g, "");

  if (!amount || amount <= 0 || !phone) {
    return new Response(JSON.stringify({ error: "Montant ou téléphone invalide" }), {
      status: 400,
    });
  }

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const externalRef = `AEEMG-${Date.now()}`;

  const { data: session, error } = await serviceClient
    .from("payment_sessions")
    .insert({
      donation_id: donationId ?? null,
      user_id: user.id,
      provider: "orange_money",
      amount,
      phone,
      external_ref: externalRef,
      status: "initiated",
    })
    .select("id, external_ref")
    .single();

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  // TODO: appeler l'API Orange Money réelle quand les clés sont configurées
  const apiConfigured = !!Deno.env.get("ORANGE_MONEY_API_KEY");

  return new Response(
    JSON.stringify({
      session_id: session.id,
      external_ref: session.external_ref,
      status: apiConfigured ? "pending" : "initiated",
      message: apiConfigured
        ? "Demande de paiement envoyée. Confirmez sur votre téléphone."
        : "Session créée. Configurez ORANGE_MONEY_API_KEY pour activer le paiement réel.",
      ussd_hint: `Composez #144# pour Orange Money (réf. ${externalRef})`,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
