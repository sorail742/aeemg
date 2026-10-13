-- SEC-006 : médias de la messagerie privés.
-- Exécution : supabase test db
begin;
select plan(13);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000e001', 'auteur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000e002', 'externe@aeemg.test');

insert into public.chat_groups (id, name, visibility) values
  ('40000000-0000-0000-0000-000000000001', 'Groupe médias test', 'private');
insert into public.chat_group_members (group_id, user_id) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000e001');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- Buckets.
select is(
  (select count(*)::int from storage.buckets
    where id in ('chat_images', 'chat_audio') and public),
  0, 'chat_images et chat_audio ne sont plus publics');
select is(
  (select file_size_limit::bigint from storage.buckets where id = 'chat_images'),
  5242880::bigint, 'chat_images limité à 5 Mo');
select is(
  (select file_size_limit::bigint from storage.buckets where id = 'chat_audio'),
  10485760::bigint, 'chat_audio limité à 10 Mo');
select ok(
  (select 'image/jpeg' = any (allowed_mime_types) and not 'text/html' = any (allowed_mime_types)
     from storage.buckets where id = 'chat_images'),
  'chat_images n''accepte que des images');

-- Reprise des anciennes URL publiques.
select is(
  public.chat_media_path(
    'https://x.supabase.co/storage/v1/object/public/chat_images/40000000-0000-0000-0000-000000000001/1.jpg'),
  '40000000-0000-0000-0000-000000000001/1.jpg', 'chat_media_path extrait le chemin d''une URL publique');
select is(public.chat_media_path('https://exemple.org/photo.jpg'), null::text,
  'chat_media_path ignore une URL étrangère');

-- Membre du groupe.
select pg_temp.login('00000000-0000-0000-0000-00000000e001');
set local role authenticated;
select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('chat_images', '40000000-0000-0000-0000-000000000001/photo.jpg',
            '00000000-0000-0000-0000-00000000e001')$$,
  'Un membre dépose une image dans le dossier de son groupe');
select is(
  (select count(*)::int from storage.objects
    where name = '40000000-0000-0000-0000-000000000001/photo.jpg'),
  1, 'Un membre lit les médias de son groupe');
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('chat_images', 'pas-un-groupe/photo.jpg', '00000000-0000-0000-0000-00000000e001')$$,
  '42501', null, 'Un chemin hors dossier de groupe est refusé');
insert into public.messages (group_id, sender_id, content, message_type, media_url) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000e001', '📸 Image', 'image',
   'https://x.supabase.co/storage/v1/object/public/chat_images/40000000-0000-0000-0000-000000000001/ancien.jpg');
select is(
  (select media_path from public.messages
    where group_id = '40000000-0000-0000-0000-000000000001' and message_type = 'image'),
  '40000000-0000-0000-0000-000000000001/ancien.jpg',
  'Un message envoyé avec media_url (ancienne app) reçoit son media_path');
reset role;

-- Membre extérieur au groupe.
select pg_temp.login('00000000-0000-0000-0000-00000000e002');
set local role authenticated;
select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'chat_images' and name like '40000000-0000-0000-0000-000000000001/%'),
  0, 'Un non-membre ne lit pas les médias du groupe');
select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('chat_audio', '40000000-0000-0000-0000-000000000001/vocal.m4a',
            '00000000-0000-0000-0000-00000000e002')$$,
  '42501', null, 'Un non-membre ne dépose rien dans le dossier du groupe');
reset role;

-- Supabase interdit tout DELETE SQL direct sur storage.objects (trigger
-- storage.protect_delete, même quand aucune ligne n'est visible) : la suppression
-- ne passe que par l'API Storage, qui applique cette policy. On vérifie donc sa
-- définition.
select ok(
  (select qual like '%owner = auth.uid()%' and qual like '%is_group_admin(%chat_media_group(name)%'
     from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and cmd = 'DELETE'
      and policyname = 'Médias de chat supprimés par l''auteur ou un admin du groupe'),
  'Suppression réservée à l''auteur du dépôt ou à un admin du groupe');

select * from finish();
rollback;
