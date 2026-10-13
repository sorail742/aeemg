-- SEC-003 : groupes privés et conversations directes.
-- Exécution : supabase test db
begin;
select plan(11);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000c001', 'a@aeemg.test'),
  ('00000000-0000-0000-0000-00000000c002', 'b@aeemg.test'),
  ('00000000-0000-0000-0000-00000000c003', 'c@aeemg.test'),
  ('00000000-0000-0000-0000-00000000c004', 'moderateur@aeemg.test');
update public.profiles set role = 'moderator' where id = '00000000-0000-0000-0000-00000000c004';

insert into public.chat_groups (id, name, visibility, created_by) values
  ('20000000-0000-0000-0000-000000000001', 'Groupe public test', 'public', null),
  ('20000000-0000-0000-0000-000000000002', 'Groupe privé test', 'private',
   '00000000-0000-0000-0000-00000000c004');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- A ouvre une conversation directe avec B et y écrit.
select pg_temp.login('00000000-0000-0000-0000-00000000c001');
set local role authenticated;
create temp table dm as
  select public.create_direct_conversation('00000000-0000-0000-0000-00000000c002') as id;
insert into public.messages (group_id, sender_id, content)
  select id, '00000000-0000-0000-0000-00000000c001', 'message privé' from dm;
select is(
  public.create_direct_conversation('00000000-0000-0000-0000-00000000c002'),
  (select id from dm),
  'create_direct_conversation réutilise la conversation existante');
reset role;

-- C, membre quelconque.
select pg_temp.login('00000000-0000-0000-0000-00000000c003');
set local role authenticated;

select throws_ok(
  format($$insert into public.chat_group_members (group_id, user_id)
           values (%L, '00000000-0000-0000-0000-00000000c003')$$, (select id from dm)),
  '42501', null, 'C ne peut pas rejoindre la conversation directe entre A et B');
select is(
  (select count(*)::int from public.messages where group_id = (select id from dm)),
  0, 'C ne lit pas les messages de la conversation directe');
select is(
  (select count(*)::int from public.chat_groups where id = (select id from dm)),
  0, 'C ne voit pas la conversation directe');
select is(
  (select count(*)::int from public.chat_groups where id = '20000000-0000-0000-0000-000000000002'),
  0, 'C ne voit pas le groupe privé');
select throws_ok(
  $$insert into public.chat_group_members (group_id, user_id)
    values ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000c003')$$,
  '42501', null, 'C ne peut pas rejoindre un groupe privé');
select lives_ok(
  $$insert into public.chat_group_members (group_id, user_id)
    values ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000c003')$$,
  'C peut rejoindre un groupe public');
select throws_ok(
  $$insert into public.chat_group_members (group_id, user_id)
    values ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000c001')$$,
  '42501', null, 'Un simple membre ne peut pas ajouter un tiers');
reset role;

-- Le modérateur, propriétaire du groupe privé.
select pg_temp.login('00000000-0000-0000-0000-00000000c004');
set local role authenticated;
select lives_ok(
  $$insert into public.chat_group_members (group_id, user_id)
    values ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000c003')$$,
  'Le propriétaire du groupe privé peut y ajouter un membre');
select throws_ok(
  format($$insert into public.chat_group_members (group_id, user_id)
           values (%L, '00000000-0000-0000-0000-00000000c004')$$, (select id from dm)),
  '42501', null, 'Même le staff ne peut pas entrer dans une conversation directe');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000c003');
set local role authenticated;
select is(
  (select count(*)::int from public.chat_groups where id = '20000000-0000-0000-0000-000000000002'),
  1, 'C voit le groupe privé une fois ajouté');
reset role;

select * from finish();
rollback;
