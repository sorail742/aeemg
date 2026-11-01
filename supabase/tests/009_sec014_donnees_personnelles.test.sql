-- SEC-014 : Protection des données personnelles des profils.
-- Exécution : supabase test db
begin;
select plan(10);

-- 1. Configuration des comptes de test
insert into auth.users (id, email, phone) values
  ('00000000-0000-0000-0000-00000000d001', 'membre1@aeemg.test', '+224600000001'),
  ('00000000-0000-0000-0000-00000000d002', 'membre2@aeemg.test', '+224600000002'),
  ('00000000-0000-0000-0000-00000000d003', 'staff@aeemg.test', '+224600000003'),
  ('00000000-0000-0000-0000-00000000d004', 'prive@aeemg.test', '+224600000004');

-- Le trigger crée les profils avec is_profile_public = false.
-- On passe membre1, membre2 et staff en public pour l'annuaire, staff en moderator.
update public.profiles set is_profile_public = true where id in (
  '00000000-0000-0000-0000-00000000d001',
  '00000000-0000-0000-0000-00000000d002',
  '00000000-0000-0000-0000-00000000d003'
);
update public.profiles set role = 'moderator' where id = '00000000-0000-0000-0000-00000000d003';

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- 2. Nettoyage et vérification de profiles.phone (aucun email dans phone) -------------------

select is(
  (select count(*)::int from public.profiles where phone like '%@%'),
  0,
  'Aucune adresse email ne subsiste dans profiles.phone'
);

select throws_ok(
  $$update public.profiles set phone = 'test@aeemg.test' where id = '00000000-0000-0000-0000-00000000d001'$$,
  '23514', null,
  'La contrainte profiles_phone_not_email interdit d''insérer un email dans phone'
);

-- 3. Nouveaux comptes privés par défaut --------------------------------------------------

select is(
  (select is_profile_public from public.profiles where id = '00000000-0000-0000-0000-00000000d004'),
  false,
  'Un nouveau profil a is_profile_public à false par défaut'
);

-- 4. Visiteur anonyme (anon) ne lit aucun profil -----------------------------------------

set local role anon;

select is(
  (select count(*)::int from public.profiles),
  0,
  'Un visiteur anonyme (anon) ne lit aucun profil dans profiles'
);

select throws_ok(
  $$select count(*)::int from public.member_directory$$,
  '42501', null,
  'Un visiteur anonyme (anon) n''a aucun droit sur member_directory (permission denied)'
);

reset role;

-- 5. Membre authentifié : ne lit pas le téléphone d'un autre membre ---------------------

select pg_temp.login('00000000-0000-0000-0000-00000000d001');
set local role authenticated;

-- Dans profiles : ne lit pas la ligne de membre 2
select is(
  (select phone from public.profiles where id = '00000000-0000-0000-0000-00000000d002'),
  null::text,
  'Un membre ne lit pas le profil d''un autre membre dans profiles'
);

-- Dans member_directory : voit le profil public mais le téléphone est masqué (null)
select is(
  (select phone from public.member_directory where id = '00000000-0000-0000-0000-00000000d002'),
  null::text,
  'Un membre ne lit pas le téléphone d''un autre membre via member_directory'
);

-- Lit son propre téléphone dans profiles et member_directory
select is(
  (select phone from public.profiles where id = '00000000-0000-0000-0000-00000000d001'),
  '+224600000001',
  'Un membre lit son propre téléphone dans profiles'
);

select is(
  (select phone from public.member_directory where id = '00000000-0000-0000-0000-00000000d001'),
  '+224600000001',
  'Un membre lit son propre téléphone dans member_directory'
);

reset role;

-- 6. Membre du staff : lit le téléphone pour la gestion ----------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000d003');
set local role authenticated;

select is(
  (select phone from public.member_directory where id = '00000000-0000-0000-0000-00000000d001'),
  '+224600000001',
  'Un membre du staff lit le téléphone d''un membre dans member_directory'
);

reset role;

select * from finish();
rollback;
