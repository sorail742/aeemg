-- SEC-021 / ADR-0008 : matrice rôles × helpers, doublons de policies, dépréciation de `staff`.
-- Le test Dart test/profile_roles_test.dart vérifie la même matrice côté `MemberProfile`.
-- Exécution : supabase test db
begin;
select plan(14);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000e001', 'super@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e002', 'admin@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e003', 'moderateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e004', 'tresorier@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e005', 'section@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e006', 'membre@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e007', 'benevole@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e008', 'visiteur@aeemg.test');
-- Exécuté en tant que propriétaire : le trigger laisse passer.
update public.profiles p set role = r.role::public.user_role
  from (values
    ('00000000-0000-0000-0000-00000000e001'::uuid, 'super_admin'),
    ('00000000-0000-0000-0000-00000000e002'::uuid, 'admin'),
    ('00000000-0000-0000-0000-00000000e003'::uuid, 'moderator'),
    ('00000000-0000-0000-0000-00000000e004'::uuid, 'treasurer'),
    ('00000000-0000-0000-0000-00000000e005'::uuid, 'section_lead'),
    ('00000000-0000-0000-0000-00000000e006'::uuid, 'member'),
    ('00000000-0000-0000-0000-00000000e007'::uuid, 'volunteer'),
    ('00000000-0000-0000-0000-00000000e008'::uuid, 'visitor')
  ) as r(id, role)
 where p.id = r.id;

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- is_staff / is_admin / is_treasurer pour chaque rôle (cf. docs/ADMIN_GUIDE.md).
create function pg_temp.helpers(uid uuid) returns text language plpgsql as $$
begin
  perform pg_temp.login(uid);
  return format('%s/%s/%s', public.is_staff(), public.is_admin(), public.is_treasurer());
end;
$$;

select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e001'), 't/t/t', 'super_admin : staff, admin, trésorier');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e002'), 't/t/t', 'admin : staff, admin, trésorier');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e003'), 't/f/f', 'moderator : staff seulement');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e004'), 'f/f/t', 'treasurer : trésorier seulement');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e005'), 't/f/f', 'section_lead : staff seulement');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e006'), 'f/f/f', 'member : aucun');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e007'), 'f/f/f', 'volunteer : aucun');
select is(pg_temp.helpers('00000000-0000-0000-0000-00000000e008'), 'f/f/f', 'visitor : aucun');

-- Une seule policy par opération d'écriture sur events.
select is(
  (select count(*)::int from pg_policies
    where schemaname = 'public' and tablename = 'events' and cmd = 'INSERT'),
  1, 'events : une seule policy INSERT');
select is(
  (select count(*)::int from pg_policies
    where schemaname = 'public' and tablename = 'events' and cmd = 'UPDATE'),
  1, 'events : une seule policy UPDATE');
select is(
  (select count(*)::int from pg_policies
    where schemaname = 'public' and tablename = 'events' and cmd = 'DELETE'),
  1, 'events : une seule policy DELETE');

-- `staff` est déprécié.
select is(
  (select count(*)::int from pg_policies
    where schemaname = 'public'
      and (coalesce(qual, '') ~ '''staff''' or coalesce(with_check, '') ~ '''staff''')),
  0, 'Aucune policy ne cite le rôle staff');
select is(
  (select count(*)::int from public.profiles where role::text = 'staff'),
  0, 'Aucun profil staff');

select pg_temp.login('00000000-0000-0000-0000-00000000e001');
set local role authenticated;
select throws_ok(
  $$select public.set_member_role('00000000-0000-0000-0000-00000000e006', 'staff')$$,
  '23514', null, 'Le rôle staff ne peut plus être attribué');
reset role;

select * from finish();
rollback;
