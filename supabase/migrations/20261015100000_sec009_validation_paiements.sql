-- SEC-009 — Réserver la validation et la consultation des sessions de paiement au trésorier / service role
--
-- Contexte :
--   La policy "Staff gere paiements" de la phase 4 autorisait tout membre du staff
--   (y compris modérateurs et responsables de section) à modifier les payment_sessions.
--   De plus, la policy legacy "Ses sessions paiement" (user_id = auth.uid() or public.is_staff())
--   permettait aux modérateurs et section leads de lire l'ensemble des sessions de paiement.
--
-- Correction :
--   1. Remplacement de la policy SELECT legacy "Ses sessions paiement" : seuls le
--      propriétaire (user_id = auth.uid()) et le trésorier (public.is_treasurer())
--      peuvent lire les sessions de paiement.
--   2. Suppression de la policy permissive UPDATE "Staff gere paiements" et
--      création de la policy "Trésorier gère les paiements" restreinte à public.is_treasurer().
--   3. Le service role (Edge Functions webhook) bénéficie nativement de BYPASSRLS
--      dans Supabase.

-- 1. Lecture des sessions : propriétaire ou trésorier uniquement
drop policy if exists "Ses sessions paiement" on public.payment_sessions;
drop policy if exists "Trésorier voit les sessions de paiement" on public.payment_sessions;
drop policy if exists "Paiements visibles par le propriétaire ou le trésorier" on public.payment_sessions;
create policy "Paiements visibles par le propriétaire ou le trésorier"
  on public.payment_sessions for select
  using (user_id = auth.uid() or public.is_treasurer());

-- 2. Mise à jour des sessions : réservée au trésorier
drop policy if exists "Staff gere paiements" on public.payment_sessions;
drop policy if exists "Trésorier gère les paiements" on public.payment_sessions;
create policy "Trésorier gère les paiements"
  on public.payment_sessions for update
  using (public.is_treasurer())
  with check (public.is_treasurer());

