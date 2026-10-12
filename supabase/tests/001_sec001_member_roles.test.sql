-- SEC-001 / ADR-0008 : modification des rôles et des colonnes protégées de profiles.
-- Exécution : supabase test db
begin;
select plan(12);

-- Comptes de test (le trigger handle_new_user crée les profils en `member`).
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000b001', 'membre@aeemg.test'),
  ('00000000-0000-0000-0000-00000000b002', 'moderateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000b003', 'admin@aeemg.test'),
  ('00000000-0000-0000-0000-00000000b004', 'super@aeemg.test');
-- Exécuté en tant que propriétaire : le trigger laisse passer.
update public.profiles set role = 'moderator'   where id = '00000000-0000-0000-0000-00000000b002';
update public.profiles set role = 'admin'       where id = '00000000-0000-0000-0000-00000000b003';
update public.profiles set role = 'super_admin' where id = '00000000-0000-0000-0000-00000000b004';

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- Membre ----------------------------------------------------------------------------
select pg_temp.login('00000000-0000-0000-0000-00000000b001');
set local role authenticated;

select throws_ok(
  $$update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-00000000b001'$$,
  '42501', null, 'Un membre ne peut pas changer son propre rôle');
select throws_ok(
  $$update public.profiles set followers_count = 999 where id = '00000000-0000-0000-0000-00000000b001'$$,
  '42501', null, 'Un membre ne peut pas modifier ses compteurs d''abonnés');
select lives_ok(
  $$update public.profiles set full_name = 'Nom modifié', section = 'Conakry'
     where id = '00000000-0000-0000-0000-00000000b001'$$,
  'Un membre peut modifier son nom et sa section');
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b001', 'admin')$$,
  '42501', null, 'Un membre ne peut pas appeler set_member_role');

reset role;

-- Modérateur ------------------------------------------------------------------------
select pg_temp.login('00000000-0000-0000-0000-00000000b002');
set local role authenticated;

update public.profiles set full_name = 'Piraté' where id = '00000000-0000-0000-0000-00000000b001';
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b001', 'staff')$$,
  '42501', null, 'Un modérateur ne peut changer le rôle de personne');

reset role;
select is(
  (select full_name from public.profiles where id = '00000000-0000-0000-0000-00000000b001'),
  'Nom modifié',
  'Un modérateur ne peut pas modifier le profil d''un autre membre');

-- Admin -----------------------------------------------------------------------------
select pg_temp.login('00000000-0000-0000-0000-00000000b003');
set local role authenticated;

select lives_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b001', 'moderator')$$,
  'Un admin peut nommer un modérateur');
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b001', 'super_admin')$$,
  '42501', null, 'Un admin ne peut pas attribuer super_admin');
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b004', 'member')$$,
  '42501', null, 'Un admin ne peut pas rétrograder un super_admin');

reset role;

-- Super admin -----------------------------------------------------------------------
select pg_temp.login('00000000-0000-0000-0000-00000000b004');
set local role authenticated;

select lives_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b001', 'admin')$$,
  'Un super_admin peut nommer un admin');
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000b004', 'member')$$,
  '42501', null, 'Le dernier super_admin ne peut pas être rétrogradé');

reset role;
select is(
  (select role::text from public.profiles where id = '00000000-0000-0000-0000-00000000b001'),
  'admin',
  'Le rôle final reflète uniquement les changements autorisés');

select * from finish();
rollback;
