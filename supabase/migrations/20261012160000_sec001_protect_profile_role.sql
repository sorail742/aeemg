-- SEC-001 — Empêcher un membre de modifier son propre rôle (escalade de privilèges)
--
-- Avant : les policies « Mise a jour de son propre profil » et « Staff modifie les rôles »
-- autorisaient un UPDATE de toutes les colonnes de profiles ; n'importe quel membre pouvait
-- exécuter `update profiles set role = 'super_admin' where id = auth.uid()`, et tout staff
-- pouvait modifier le profil (et le rôle) de n'importe qui.
--
-- Après :
--   1. un trigger refuse toute modification des colonnes protégées (role, compteurs,
--      created_at, id) faite par un client (rôles authenticated / anon), sauf via la RPC
--      set_member_role ;
--   2. la RPC set_member_role applique la matrice d'ADR-0008 ;
--   3. chacun ne peut mettre à jour que son propre profil.

-- 1. Garde des colonnes protégées ------------------------------------------------------

create or replace function public.protect_profile_columns()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  -- Les fonctions SECURITY DEFINER (compteurs d'abonnés, set_member_role) s'exécutent
  -- avec le rôle propriétaire : seules les requêtes directes des clients sont contrôlées.
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if new.role is distinct from old.role
     and coalesce(current_setting('aeemg.allow_role_change', true), '') <> 'on' then
    raise exception 'Le rôle ne peut être modifié que via set_member_role (SEC-001)'
      using errcode = '42501';
  end if;

  if new.id is distinct from old.id
     or new.created_at is distinct from old.created_at
     or new.followers_count is distinct from old.followers_count
     or new.following_count is distinct from old.following_count then
    raise exception 'Colonne protégée de profiles : modification refusée (SEC-001)'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns
  before update on public.profiles
  for each row execute function public.protect_profile_columns();

-- 2. Changement de rôle contrôlé -------------------------------------------------------

create or replace function public.set_member_role(target uuid, new_role public.user_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_role public.user_role;
  target_role public.user_role;
begin
  select role into caller_role from public.profiles where id = auth.uid();
  if caller_role is null or caller_role::text not in ('super_admin', 'admin') then
    raise exception 'Seul un administrateur peut changer un rôle'
      using errcode = '42501';
  end if;

  select role into target_role from public.profiles where id = target;
  if target_role is null then
    raise exception 'Membre introuvable' using errcode = 'P0002';
  end if;

  -- Attribuer ou retirer admin / super_admin est réservé au super_admin.
  if caller_role::text <> 'super_admin'
     and (new_role::text in ('super_admin', 'admin')
          or target_role::text in ('super_admin', 'admin')) then
    raise exception 'Seul un super_admin peut attribuer ou retirer les rôles admin et super_admin'
      using errcode = '42501';
  end if;

  -- Ne jamais laisser l'association sans super_admin.
  if target_role::text = 'super_admin' and new_role::text <> 'super_admin'
     and (select count(*) from public.profiles where role::text = 'super_admin') <= 1 then
    raise exception 'Impossible de rétrograder le dernier super_admin'
      using errcode = '42501';
  end if;

  perform set_config('aeemg.allow_role_change', 'on', true);
  update public.profiles set role = new_role where id = target;
  perform set_config('aeemg.allow_role_change', 'off', true);
end;
$$;

revoke all on function public.set_member_role(uuid, public.user_role) from public, anon;
grant execute on function public.set_member_role(uuid, public.user_role) to authenticated;

-- 3. Chacun ne met à jour que son propre profil ----------------------------------------

drop policy if exists "Staff modifie les rôles" on public.profiles;
drop policy if exists "Mise a jour de son propre profil" on public.profiles;
create policy "Mise a jour de son propre profil"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
