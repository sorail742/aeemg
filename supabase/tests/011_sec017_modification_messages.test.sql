-- SEC-017 : Restreindre la modification des messages.
-- Exécution : supabase test db
begin;
select plan(13);

-- 1. Configuration des comptes, groupes et messages de test -------------------------------

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-000000017001', 'admin17@aeemg.test'),
  ('00000000-0000-0000-0000-000000017002', 'sender17@aeemg.test'),
  ('00000000-0000-0000-0000-000000017003', 'other17@aeemg.test');

insert into public.chat_groups (id, name, visibility, created_by) values
  ('aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', 'Groupe Discussion A', 'private', '00000000-0000-0000-0000-000000017001'),
  ('bbbbbbbb-1717-1717-1717-bbbbbbbbbbbb', 'Groupe Discussion B', 'private', '00000000-0000-0000-0000-000000017001');

insert into public.chat_group_members (group_id, user_id, member_role) values
  ('aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000017001', 'admin'),
  ('aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000017002', 'member'),
  ('aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000017003', 'member')
on conflict (group_id, user_id) do update set member_role = excluded.member_role;

-- Deux messages créés par sender17 : l'un récent (< 15 min), l'autre ancien (> 15 min)
insert into public.messages (id, group_id, sender_id, content, created_at) values
  ('11111111-1717-1717-1717-111111111111', 'aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000017002', 'Message recent', now() - interval '2 minutes'),
  ('22222222-1717-1717-1717-222222222222', 'aaaaaaaa-1717-1717-1717-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000017002', 'Message ancien', now() - interval '30 minutes');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- 2. Tests de l'expéditeur (sender17) ----------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-000000017002');
set local role authenticated;

-- Modifie content dans la fenêtre de 15 minutes
select lives_ok(
  $$update public.messages set content = 'Message recent modifie' where id = '11111111-1717-1717-1717-111111111111'$$,
  'L''expediteur peut modifier le contenu de son message dans les 15 minutes'
);

-- Refus de modification de content après 15 minutes
select throws_ok(
  $$update public.messages set content = 'Tentative tardive' where id = '22222222-1717-1717-1717-222222222222'$$,
  '42501', null,
  'L''expediteur ne peut pas modifier le contenu apres 15 minutes'
);

-- Modifie is_deleted (suppression logique)
select lives_ok(
  $$update public.messages set is_deleted = true where id = '11111111-1717-1717-1717-111111111111'$$,
  'L''expediteur peut marquer son message comme supprime (is_deleted)'
);

-- Refus de modifier is_pinned si non-modérateur
select throws_ok(
  $$update public.messages set is_pinned = true where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'L''expediteur non-moderateur ne peut pas epingler son message (is_pinned)'
);

-- Refus de modifier group_id (déplacement de message)
select throws_ok(
  $$update public.messages set group_id = 'bbbbbbbb-1717-1717-1717-bbbbbbbbbbbb' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de group_id interdite'
);

-- Refus de modifier sender_id (usurpation d''expéditeur)
select throws_ok(
  $$update public.messages set sender_id = '00000000-0000-0000-0000-000000017003' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de sender_id interdite'
);

-- Refus de modifier created_at
select throws_ok(
  $$update public.messages set created_at = now() where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de created_at interdite'
);

-- Refus de modifier message_type
select throws_ok(
  $$update public.messages set message_type = 'audio' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de message_type interdite'
);

-- Refus de modifier media_url
select throws_ok(
  $$update public.messages set media_url = 'https://malicious.org/exploit.jpg' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de media_url interdite'
);

-- Refus de modifier id
select throws_ok(
  $$update public.messages set id = '99999999-1717-1717-1717-999999999999' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Modification de id interdite'
);

reset role;

-- 3. Tests du modérateur / admin du groupe (admin17) --------------------------------------

select pg_temp.login('00000000-0000-0000-0000-000000017001');
set local role authenticated;

-- L'admin du groupe peut épingler un message
select lives_ok(
  $$update public.messages set is_pinned = true where id = '11111111-1717-1717-1717-111111111111'$$,
  'Un admin/moderateur du groupe peut epingler un message (is_pinned = true)'
);

-- L'admin du groupe ne peut pas modifier le contenu d'un tiers
select throws_ok(
  $$update public.messages set content = 'Altere par admin' where id = '11111111-1717-1717-1717-111111111111'$$,
  '42501', null,
  'Un admin du groupe ne peut pas modifier le contenu d''un message d''un tiers'
);

reset role;

-- 4. Tests d'un membre tiers (other17) ---------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-000000017003');
set local role authenticated;

-- Un membre tiers non-admin ne peut toucher a aucun message de tiers
select is(
  (with upd as (
    update public.messages set content = 'Tentative hack' where id = '11111111-1717-1717-1717-111111111111' returning *
  ) select count(*)::int from upd),
  0,
  'Un membre tiers ne peut pas modifier le message d''un autre membre (RLS bloque 0 ligne)'
);

reset role;

select * from finish();
rollback;
