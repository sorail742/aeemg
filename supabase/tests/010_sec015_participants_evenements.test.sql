-- SEC-015 : Masquer les participants aux événements pour les visiteurs anonymes.
-- Exécution : supabase test db
begin;
select plan(11);

-- 1. Configuration des comptes et événements de test --------------------------------------

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000e001', 'participant1@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e002', 'participant2@aeemg.test');

insert into public.events (id, title, starts_at) values
  ('11111111-1111-1111-1111-111111111111', 'Conférence Annuelle', now() + interval '5 days'),
  ('22222222-2222-2222-2222-222222222222', 'Atelier Vide', now() + interval '10 days');

insert into public.event_rsvps (event_id, user_id, status) values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000e001', 'going'),
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000e002', 'maybe');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- 2. Membre connecté peut lire les participations ----------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000e001');
set local role authenticated;

select is(
  (select count(*)::int from public.event_rsvps where event_id = '11111111-1111-1111-1111-111111111111'),
  2,
  'Un utilisateur connecté peut lire les participations dans event_rsvps'
);

select is(
  (select going_count from public.event_rsvp_counts where event_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'Un utilisateur connecté peut lire les compteurs via event_rsvp_counts'
);

select is(
  public.get_event_rsvp_count('11111111-1111-1111-1111-111111111111', 'going'),
  1,
  'Un utilisateur connecté peut appeler get_event_rsvp_count'
);

-- 3. Visiteur anonyme (anon) ne lit aucun participant dans event_rsvps -------------------

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);

select is(
  (select count(*)::int from public.event_rsvps),
  0,
  'Visiteur anonyme ne lit aucun participant dans event_rsvps (0 ligne)'
);

select is(
  (select count(*)::int from public.event_rsvps where event_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Visiteur anonyme ne peut filtrer aucun participant'
);

-- 4. Compteurs publics accessibles à anon via la vue -------------------------------------

select is(
  (select going_count from public.event_rsvp_counts where event_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'Visiteur anonyme accède au compteur going_count via la vue event_rsvp_counts'
);

select is(
  (select maybe_count from public.event_rsvp_counts where event_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'Visiteur anonyme accède au compteur maybe_count via la vue event_rsvp_counts'
);

select is(
  (select total_count from public.event_rsvp_counts where event_id = '11111111-1111-1111-1111-111111111111'),
  2,
  'Visiteur anonyme accède au compteur total_count via la vue event_rsvp_counts'
);

select is(
  (select total_count from public.event_rsvp_counts where event_id = '22222222-2222-2222-2222-222222222222'),
  0,
  'Événement sans inscription affiche un compteur public à 0 via la vue'
);

-- 5. Compteurs publics accessibles à anon via la fonction RPC ----------------------------

select is(
  public.get_event_rsvp_count('11111111-1111-1111-1111-111111111111', 'going'),
  1,
  'Visiteur anonyme accède au compteur going via la RPC get_event_rsvp_count'
);

select is(
  public.get_event_rsvp_count('22222222-2222-2222-2222-222222222222', 'going'),
  0,
  'Visiteur anonyme obtient 0 pour un événement sans inscription via la RPC'
);

select * from finish();
rollback;
