-- SEC-007 : Encadrement des uploads du bucket social_images.
-- Exécution : supabase test db
begin;
select plan(11);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000s001', 'auteur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000s002', 'autre@aeemg.test');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- 1. Configuration du bucket -------------------------------------------------------------

select ok(
  (select public from storage.buckets where id = 'social_images'),
  'social_images est un bucket public');

select is(
  (select file_size_limit::bigint from storage.buckets where id = 'social_images'),
  5242880::bigint,
  'social_images est limité à 5 Mo');

select ok(
  (select 'image/jpeg' = any (allowed_mime_types)
      and 'image/png' = any (allowed_mime_types)
      and 'image/webp' = any (allowed_mime_types)
      and not 'text/html' = any (allowed_mime_types)
     from storage.buckets where id = 'social_images'),
  'social_images n''accepte que les formats d''images jpeg, png et webp');

-- 2. Fonction d'extraction de chemin -----------------------------------------------------

select is(
  public.social_image_path(
    'https://xyz.supabase.co/storage/v1/object/public/social_images/00000000-0000-0000-0000-00000000s001/photo.jpg'),
  '00000000-0000-0000-0000-00000000s001/photo.jpg',
  'social_image_path extrait le chemin d''une URL publique social_images');

select is(
  public.social_image_path('https://exemple.org/photo.jpg'),
  null::text,
  'social_image_path ignore une URL étrangère');

-- 3. Dépôt par un utilisateur authentifié ------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000s001');
set local role authenticated;

select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('social_images', '00000000-0000-0000-0000-00000000s001/photo.jpg',
            '00000000-0000-0000-0000-00000000s001')$$,
  'Un utilisateur dépose une image dans son propre sous-dossier <uid>/...');

select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'social_images'
      and name = '00000000-0000-0000-0000-00000000s001/photo.jpg'),
  1,
  'L''utilisateur peut lire son image');

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('social_images', 'racine.jpg', '00000000-0000-0000-0000-00000000s001')$$,
  '42501', null,
  'Un upload à la racine du bucket est refusé');

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner)
    values ('social_images', '00000000-0000-0000-0000-00000000s002/photo.jpg',
            '00000000-0000-0000-0000-00000000s001')$$,
  '42501', null,
  'Un upload dans le dossier d''un autre utilisateur est refusé');

reset role;

-- 4. Lecture publique par un tiers -------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000s002');
set local role authenticated;

select is(
  (select count(*)::int from storage.objects
    where bucket_id = 'social_images'
      and name = '00000000-0000-0000-0000-00000000s001/photo.jpg'),
  1,
  'Un autre membre peut lire l''image publique du post');

reset role;

-- 5. Politique de suppression ------------------------------------------------------------

-- Supabase interdit tout DELETE SQL direct sur storage.objects (trigger
-- storage.protect_delete) : la suppression passe par l'API Storage, qui applique
-- la policy DELETE. On vérifie sa définition en base.
select ok(
  (select (qual like '%owner = auth.uid()%' or qual like '%auth.uid() = owner%')
      and qual like '%storage.foldername%name%'
      and qual like '%is_staff()%'
     from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and cmd = 'DELETE'
      and policyname = 'Utilisateurs et staff suppriment leurs images'),
  'Suppression autorisée au propriétaire de l''image et aux membres du staff');

select * from finish();
rollback;
