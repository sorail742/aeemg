-- SEC-006 — Rendre privés les médias de la messagerie (images, audio)
--
-- Avant (phase6_advanced_messaging.sql) : buckets chat_images et chat_audio publics, lecture
-- ouverte à tous (`using (bucket_id = ...)`), insertion par n'importe quel connecté, aucune
-- limite de taille ni de type. messages.media_url stockait une URL publique permanente.
--
-- Après :
--   * buckets privés, 5 Mo (jpeg/png/webp) / 10 Mo (m4a/ogg/webm), conformément à ADR-0018 ;
--   * objets rangés sous `<group_id>/...` : lecture et dépôt réservés aux membres du groupe,
--     suppression par l'auteur de l'envoi ou un admin du groupe ;
--   * messages.media_path stocke le chemin dans le bucket ; le client génère des URL signées.
--     Les anciens messages sont repris depuis media_url (conservée, dépréciée).

-- 1. Buckets -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('chat_images', 'chat_images', false, 5242880,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('chat_audio', 'chat_audio', false, 10485760,
   array['audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/ogg', 'audio/webm'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Groupe propriétaire d'un objet ------------------------------------------------------

-- Premier segment du chemin, s'il s'agit d'un UUID (sinon null : aucun accès). Équivaut à
-- (storage.foldername(name))[1]::uuid prévu par ADR-0018, sans l'erreur de conversion qui
-- ferait échouer toute la requête pour un objet mal rangé.
create or replace function public.chat_media_group(object_name text)
returns uuid
language sql immutable set search_path = ''
as $$
  select case
    when split_part(object_name, '/', 1)
         ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(object_name, '/', 1)::uuid
  end;
$$;

-- 3. Policies Storage --------------------------------------------------------------------

drop policy if exists "Images de chat lisibles" on storage.objects;
drop policy if exists "Images de chat insérables" on storage.objects;
drop policy if exists "Audio de chat lisibles" on storage.objects;
drop policy if exists "Audio de chat insérables" on storage.objects;

drop policy if exists "Médias de chat lisibles par les membres du groupe" on storage.objects;
create policy "Médias de chat lisibles par les membres du groupe"
  on storage.objects for select
  using (
    bucket_id in ('chat_images', 'chat_audio')
    and public.is_group_member(public.chat_media_group(name))
  );

drop policy if exists "Médias de chat déposés par les membres du groupe" on storage.objects;
create policy "Médias de chat déposés par les membres du groupe"
  on storage.objects for insert
  with check (
    bucket_id in ('chat_images', 'chat_audio')
    and auth.uid() is not null
    and public.is_group_member(public.chat_media_group(name))
  );

drop policy if exists "Médias de chat supprimés par l'auteur ou un admin du groupe" on storage.objects;
create policy "Médias de chat supprimés par l'auteur ou un admin du groupe"
  on storage.objects for delete
  using (
    bucket_id in ('chat_images', 'chat_audio')
    and (owner = auth.uid() or public.is_group_admin(public.chat_media_group(name)))
  );

-- 4. Chemin du média dans messages -------------------------------------------------------

alter table public.messages add column if not exists media_path text;

-- Extrait le chemin d'une ancienne URL publique
-- (…/storage/v1/object/public/chat_images/<group_id>/<fichier>?…).
create or replace function public.chat_media_path(media_url text)
returns text
language sql immutable set search_path = ''
as $$
  select substring(media_url from '/storage/v1/object/(?:public|sign)/chat_(?:images|audio)/([^?#]+)');
$$;

update public.messages
   set media_path = public.chat_media_path(media_url)
 where media_path is null
   and media_url is not null;

-- Les anciennes versions de l'app envoient encore media_url : on en déduit le chemin.
create or replace function public.messages_fill_media_path()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.media_path is null and new.media_url is not null then
    new.media_path := public.chat_media_path(new.media_url);
  end if;
  return new;
end;
$$;

drop trigger if exists messages_fill_media_path on public.messages;
create trigger messages_fill_media_path
  before insert or update of media_url, media_path on public.messages
  for each row execute function public.messages_fill_media_path();

comment on column public.messages.media_url is
  'Déprécié (SEC-006) : URL publique des anciennes versions. Utiliser media_path + URL signée.';
comment on column public.messages.media_path is
  'Chemin de l''objet dans chat_images / chat_audio (selon message_type), préfixé par group_id.';
