-- SEC-015 — Masquer les participants aux événements pour les visiteurs anonymes
--
-- Contexte :
--   event_rsvps : SELECT using (true) → anon voit qui participe à quoi.
--
-- Actions :
--   1. Remplacer la policy SELECT permissive par une policy réservée aux utilisateurs
--      connectés (auth.role() = 'authenticated').
--   2. Créer une vue agrégée public.event_rsvp_counts avec (security_invoker = false)
--      permettant aux visiteurs (anon) et aux membres de consulter les compteurs de
--      participants par statut sans exposer l'identité des membres (user_id).
--   3. Créer une fonction RPC public.get_event_rsvp_count(uuid, rsvp_status) security definer
--      avec search_path = '' (SEC-013) pour un comptage ciblé par événement.
--   4. Ajuster les droits GRANT / REVOKE.

-- 1. Restriction de la lecture sur public.event_rsvps -------------------------------------

drop policy if exists "RSVP visibles" on public.event_rsvps;
drop policy if exists "RSVP visibles par membres connectes" on public.event_rsvps;

create policy "RSVP visibles par membres connectes"
  on public.event_rsvps for select
  to authenticated
  using (auth.role() = 'authenticated');

-- Révocation explicite de select pour anon sur la table brute
revoke select on public.event_rsvps from anon;

-- 2. Vue agrégée pour les compteurs publics -----------------------------------------------

create or replace view public.event_rsvp_counts
with (security_invoker = false)
as
select
  e.id as event_id,
  coalesce(count(r.user_id), 0)::integer as total_count,
  coalesce(count(r.user_id) filter (where r.status = 'going'), 0)::integer as going_count,
  coalesce(count(r.user_id) filter (where r.status = 'maybe'), 0)::integer as maybe_count,
  coalesce(count(r.user_id) filter (where r.status = 'not_going'), 0)::integer as not_going_count
from public.events e
left join public.event_rsvps r on r.event_id = e.id
group by e.id;

comment on view public.event_rsvp_counts is
  'Compteurs agrégés de participants par événement, accessibles publiquement sans exposer les user_id (SEC-015).';

grant select on public.event_rsvp_counts to anon, authenticated;

-- 3. Fonction RPC de comptage public -----------------------------------------------------

create or replace function public.get_event_rsvp_count(
  p_event_id uuid,
  p_status public.rsvp_status default 'going'
)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(count(*), 0)::integer
  from public.event_rsvps
  where event_id = p_event_id
    and (p_status is null or status = p_status);
$$;

comment on function public.get_event_rsvp_count(uuid, public.rsvp_status) is
  'Compteur public de participants pour un événement donné et un statut donné (SEC-015).';

grant execute on function public.get_event_rsvp_count(uuid, public.rsvp_status) to anon, authenticated;
