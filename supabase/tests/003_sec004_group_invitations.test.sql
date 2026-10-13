-- SEC-004 : invitations par numéro de téléphone.
-- Exécution : supabase test db
begin;
select plan(11);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000d001', 'proprietaire@aeemg.test'),
  ('00000000-0000-0000-0000-00000000d002', 'membre@aeemg.test'),
  ('00000000-0000-0000-0000-00000000d003', 'externe@aeemg.test'),
  ('00000000-0000-0000-0000-00000000d004', 'moderateur@aeemg.test');
update public.profiles set role = 'moderator' where id = '00000000-0000-0000-0000-00000000d004';

-- d001 crée le groupe (il en devient owner par trigger), d002 en est simple membre.
insert into public.chat_groups (id, name, visibility, created_by) values
  ('30000000-0000-0000-0000-000000000001', 'Groupe test invitations', 'public',
   '00000000-0000-0000-0000-00000000d001'),
  ('30000000-0000-0000-0000-000000000002', null, 'direct', null);
update public.chat_groups set is_group = false where id = '30000000-0000-0000-0000-000000000002';
insert into public.chat_group_members (group_id, user_id) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000d002');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select is(
  (select count(*)::int from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'group_invitations'),
  0, 'group_invitations n''est plus diffusée en Realtime');
select ok(
  not has_table_privilege('anon', 'public.group_invitations', 'select'),
  'anon ne peut pas lire les invitations');

-- Le propriétaire du groupe invite un numéro.
select pg_temp.login('00000000-0000-0000-0000-00000000d001');
set local role authenticated;
select lives_ok(
  $$insert into public.group_invitations (group_id, phone_number)
    values ('30000000-0000-0000-0000-000000000001', '+224620000001')$$,
  'Le propriétaire du groupe peut inviter un numéro');
select is(
  (select invited_by from public.group_invitations where phone_number = '+224620000001'),
  '00000000-0000-0000-0000-00000000d001'::uuid,
  'invited_by vaut l''utilisateur connecté');
select throws_ok(
  $$insert into public.group_invitations (group_id, phone_number)
    values ('30000000-0000-0000-0000-000000000001', '620 00 00 02')$$,
  '23514', null, 'Un numéro hors format E.164 est refusé');
select throws_ok(
  $$insert into public.group_invitations (group_id, phone_number, invited_by)
    values ('30000000-0000-0000-0000-000000000001', '+224620000003',
            '00000000-0000-0000-0000-00000000d002')$$,
  '42501', null, 'On ne peut pas inviter au nom d''un autre');
reset role;

-- Un simple membre du groupe.
select pg_temp.login('00000000-0000-0000-0000-00000000d002');
set local role authenticated;
select throws_ok(
  $$insert into public.group_invitations (group_id, phone_number)
    values ('30000000-0000-0000-0000-000000000001', '+224620000004')$$,
  '42501', null, 'Un membre non admin du groupe ne peut pas inviter');
select is(
  (select count(*)::int from public.group_invitations), 0,
  'Un simple membre ne voit aucune invitation');
reset role;

-- Un membre extérieur au groupe.
select pg_temp.login('00000000-0000-0000-0000-00000000d003');
set local role authenticated;
select is(
  (select count(*)::int from public.group_invitations), 0,
  'Un membre extérieur ne voit aucune invitation');
reset role;

-- Le staff voit les invitations mais ne peut pas inviter dans une conversation directe.
select pg_temp.login('00000000-0000-0000-0000-00000000d004');
set local role authenticated;
select is(
  (select count(*)::int from public.group_invitations), 1,
  'Le staff voit les invitations');
select throws_ok(
  $$insert into public.group_invitations (group_id, phone_number)
    values ('30000000-0000-0000-0000-000000000002', '+224620000005')$$,
  '42501', null, 'Aucune invitation dans une conversation directe');
reset role;

select * from finish();
rollback;
