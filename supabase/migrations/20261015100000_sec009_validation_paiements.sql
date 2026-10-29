-- SEC-009 — Réserver la validation des sessions de paiement au trésorier / service role
--
-- Contexte :
--   La policy "Staff gere paiements" de la phase 4 autorisait tout membre du staff
--   (y compris modérateurs et responsables de section) à modifier les payment_sessions.
--
-- Correction :
--   1. Suppression de la policy permissive "Staff gere paiements".
--   2. Ajout de la policy "Trésorier voit les sessions de paiement" (SELECT) pour
--      permettre au rôle `treasurer` (qui n'est pas dans is_staff()) de lire les
--      sessions, condition nécessaire sous PostgreSQL RLS pour exécuter un UPDATE.
--   3. Création de la policy "Trésorier gère les paiements" (UPDATE) restreinte
--      strictement à public.is_treasurer().
--   4. Le service role (Edge Functions webhook) bénéficie nativement de BYPASSRLS
--      dans Supabase.

-- 1. Lecture des sessions par le trésorier
drop policy if exists "Trésorier voit les sessions de paiement" on public.payment_sessions;
create policy "Trésorier voit les sessions de paiement"
  on public.payment_sessions for select
  using (public.is_treasurer());

-- 2. Mise à jour des sessions réservée au trésorier
drop policy if exists "Staff gere paiements" on public.payment_sessions;
drop policy if exists "Trésorier gère les paiements" on public.payment_sessions;
create policy "Trésorier gère les paiements"
  on public.payment_sessions for update
  using (public.is_treasurer())
  with check (public.is_treasurer());
