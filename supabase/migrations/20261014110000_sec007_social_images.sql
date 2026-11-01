-- SEC-007 — Encadrer les uploads du bucket social_images
--
-- Avant (phase5_social.sql) :
--   Bucket public sans limite de taille ni de types MIME. Tout connecté
--   pouvait insérer n'importe quel fichier à n'importe quel emplacement.
--
-- Après :
--   * Limite de taille fixée à 5 Mo (5 242 880 octets).
--   * Types MIME autorisés restreints à image/jpeg, image/png, image/webp.
--   * Upload restreint sous <auth.uid()>/... vérifié par storage.foldername(name).
--   * Suppression autorisée au propriétaire de l'image (owner ou préfixe auth.uid())
--     et aux modérateurs/staff (public.is_staff()).
--   * Fonction public.social_image_path(image_url) pour extraire le chemin.

-- 1. Configuration du bucket -------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'social_images', 'social_images', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Policies Storage --------------------------------------------------------------------

drop policy if exists "Images publiques" on storage.objects;
create policy "Images publiques"
  on storage.objects for select
  using (bucket_id = 'social_images');

drop policy if exists "Utilisateurs uploadent images" on storage.objects;
create policy "Utilisateurs uploadent images"
  on storage.objects for insert
  with check (
    bucket_id = 'social_images'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Utilisateurs gerent leurs images" on storage.objects;
drop policy if exists "Utilisateurs et staff suppriment leurs images" on storage.objects;
create policy "Utilisateurs et staff suppriment leurs images"
  on storage.objects for delete
  using (
    bucket_id = 'social_images'
    and (
      auth.uid() = owner
      or (storage.foldername(name))[1] = auth.uid()::text
      or public.is_staff()
    )
  );

-- 3. Extraction du chemin du fichier depuis une URL publique ------------------------------

create or replace function public.social_image_path(image_url text)
returns text
language sql immutable set search_path = ''
as $$
  select substring(image_url from '/storage/v1/object/public/social_images/([^?#]+)');
$$;

comment on function public.social_image_path(text) is
  'Extrait le chemin de l''objet dans le bucket social_images depuis son URL publique.';
