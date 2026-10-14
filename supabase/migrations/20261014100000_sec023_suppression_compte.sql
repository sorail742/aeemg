-- SEC-023 — Supprimer réellement un compte (auth.users), via l'Edge Function admin-delete-user
--
-- Avant :
--   * AdminRepository.deleteMember supprimait la ligne profiles (policy « Admin supprime
--     membres ») mais pas auth.users : le compte pouvait encore se connecter, sans profil ;
--   * events.created_by, announcements.author_id, chat_groups.created_by et
--     transactions.recorded_by (NO ACTION) bloquaient la suppression de tout membre ayant
--     créé un événement, une annonce, un groupe ou saisi une transaction.
--
-- Après (choix documenté dans docs/ADMIN_GUIDE.md) :
--   * données personnelles supprimées (profil, messages, posts, réactions, inscriptions…,
--     déjà en ON DELETE CASCADE) ; contenus collectifs et comptables conservés, auteur mis à
--     null (« Membre supprimé ») ;
--   * plus de suppression directe de profiles par l'API : seule l'Edge Function (service role)
--     supprime auth.users, ce qui supprime le profil en cascade ;
--   * check_member_deletion() applique les règles d'autorisation avec l'identité de l'appelant ;
--   * member_storage_objects() liste les fichiers déposés par le membre (service role seul).

-- 1. Contenus collectifs conservés --------------------------------------------------------

do $$
declare
  r record;
  fk text;
begin
  for r in
    select * from (values
      ('events', 'created_by'),
      ('announcements', 'author_id'),
      ('chat_groups', 'created_by'),
      ('transactions', 'recorded_by')
    ) as t(tbl, col)
  loop
    select c.conname into fk
      from pg_constraint c
      join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
     where c.contype = 'f'
       and c.conrelid = format('public.%I', r.tbl)::regclass
       and c.confrelid = 'public.profiles'::regclass
       and a.attname = r.col;
    if fk is not null then
      execute format('alter table public.%I drop constraint %I', r.tbl, fk);
    end if;
    execute format(
      'alter table public.%I add constraint %I foreign key (%I) '
      'references public.profiles (id) on delete set null',
      r.tbl, r.tbl || '_' || r.col || '_fkey', r.col);
  end loop;
end
$$;

-- 2. Plus de suppression directe de profils -----------------------------------------------

drop policy if exists "Admin supprime membres" on public.profiles;

-- 3. Autorisation de la suppression -------------------------------------------------------

-- Appelée par l'Edge Function avec le JWT de l'appelant : auth.uid() est l'administrateur.
-- Mêmes règles que set_member_role (ADR-0008, SEC-001).
create or replace function public.check_member_deletion(target uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller_role public.user_role;
  target_role public.user_role;
begin
  select role into caller_role from public.profiles where id = auth.uid();
  if caller_role is null or caller_role::text not in ('super_admin', 'admin') then
    raise exception 'Seul un administrateur peut supprimer un compte' using errcode = '42501';
  end if;

  if target = auth.uid() then
    raise exception 'Impossible de supprimer son propre compte depuis l''administration'
      using errcode = '42501';
  end if;

  select role into target_role from public.profiles where id = target;
  if target_role is null then
    raise exception 'Membre introuvable' using errcode = 'P0002';
  end if;

  -- Seul un super_admin supprime un admin ou un super_admin ; comme il ne peut pas se
  -- supprimer lui-même, l'association garde toujours au moins un super_admin.
  if target_role::text in ('super_admin', 'admin') and caller_role::text <> 'super_admin' then
    raise exception 'Seul un super_admin peut supprimer un administrateur'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.check_member_deletion(uuid) from public, anon;
grant execute on function public.check_member_deletion(uuid) to authenticated;

-- 4. Fichiers déposés par le membre -------------------------------------------------------

-- La suppression directe dans storage.objects est interdite : l'Edge Function supprime ces
-- fichiers par l'API Storage avant de supprimer le compte.
create or replace function public.member_storage_objects(target uuid)
returns table (bucket_id text, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select o.bucket_id, o.name from storage.objects o where o.owner = target;
$$;

revoke all on function public.member_storage_objects(uuid) from public, anon, authenticated;
grant execute on function public.member_storage_objects(uuid) to service_role;
