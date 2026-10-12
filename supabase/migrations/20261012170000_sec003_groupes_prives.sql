-- SEC-003 — Empêcher l'auto-ajout dans un groupe ou une conversation privée
--
-- Avant : la policy « Rejoindre un groupe » acceptait `auth.uid() = user_id` pour
-- N'IMPORTE QUEL chat_group (y compris une conversation 1-à-1, is_group = false), et
-- chat_groups était lisible par tous les connectés : n'importe qui pouvait s'inscrire dans
-- une conversation privée et en lire tout l'historique.
--
-- Après :
--   * chat_groups.visibility : public | private | direct
--   * chat_group_members.member_role : owner | admin | member
--   * auto-inscription uniquement aux groupes publics ; ajout d'un tiers par un admin du
--     groupe (ou le staff) hors conversations directes ; conversations directes créées
--     uniquement par la RPC create_direct_conversation ;
--   * lecture de chat_groups : groupes publics + groupes dont on est membre.

-- 1. Schéma ------------------------------------------------------------------------------

alter table public.chat_groups
  add column if not exists visibility text not null default 'public';

alter table public.chat_groups
  drop constraint if exists chat_groups_visibility_check;
alter table public.chat_groups
  add constraint chat_groups_visibility_check
  check (visibility in ('public', 'private', 'direct'));

-- Les conversations 1-à-1 existantes deviennent « direct » (aucune donnée perdue).
update public.chat_groups set visibility = 'direct' where is_group = false;

alter table public.chat_group_members
  add column if not exists member_role text not null default 'member';

alter table public.chat_group_members
  drop constraint if exists chat_group_members_member_role_check;
alter table public.chat_group_members
  add constraint chat_group_members_member_role_check
  check (member_role in ('owner', 'admin', 'member'));

-- Le créateur d'un groupe existant en devient propriétaire.
insert into public.chat_group_members (group_id, user_id, member_role)
select g.id, g.created_by, 'owner'
  from public.chat_groups g
 where g.created_by is not null
on conflict (group_id, user_id) do update set member_role = 'owner';

-- 2. Fonctions utilitaires (SECURITY DEFINER : évitent la récursion RLS) -----------------

create or replace function public.is_group_member(g uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.chat_group_members m
     where m.group_id = g and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_group_admin(g uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.chat_group_members m
     where m.group_id = g and m.user_id = auth.uid()
       and m.member_role in ('owner', 'admin')
  ) or public.is_staff();
$$;

create or replace function public.chat_group_visibility(g uuid)
returns text
language sql stable security definer set search_path = ''
as $$
  select visibility from public.chat_groups where id = g;
$$;

-- 3. Le créateur d'un nouveau groupe en devient propriétaire -----------------------------

create or replace function public.add_group_owner()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.created_by is not null and new.visibility <> 'direct' then
    insert into public.chat_group_members (group_id, user_id, member_role)
    values (new.id, new.created_by, 'owner')
    on conflict (group_id, user_id) do update set member_role = 'owner';
  end if;
  return new;
end;
$$;

drop trigger if exists on_chat_group_created on public.chat_groups;
create trigger on_chat_group_created
  after insert on public.chat_groups
  for each row execute function public.add_group_owner();

-- 4. Policies ----------------------------------------------------------------------------

drop policy if exists "Groupes visibles aux utilisateurs connectés" on public.chat_groups;
drop policy if exists "Groupes lisibles par membres" on public.chat_groups;
create policy "Groupes publics ou dont on est membre"
  on public.chat_groups for select
  using (
    auth.uid() is not null
    and (visibility = 'public' or public.is_group_member(id))
  );

-- Le staff crée des groupes publics ou privés ; les conversations directes passent par la RPC.
drop policy if exists "Staff crée des groupes" on public.chat_groups;
create policy "Staff crée des groupes"
  on public.chat_groups for insert
  with check (public.is_staff() and visibility in ('public', 'private'));

drop policy if exists "Rejoindre un groupe" on public.chat_group_members;
create policy "Rejoindre un groupe public"
  on public.chat_group_members for insert
  with check (
    user_id = auth.uid()
    and member_role = 'member'
    and public.chat_group_visibility(group_id) = 'public'
  );

drop policy if exists "Admin du groupe ajoute un membre" on public.chat_group_members;
create policy "Admin du groupe ajoute un membre"
  on public.chat_group_members for insert
  with check (
    public.is_group_admin(group_id)
    and public.chat_group_visibility(group_id) in ('public', 'private')
  );

drop policy if exists "Quitter un groupe" on public.chat_group_members;
create policy "Quitter un groupe"
  on public.chat_group_members for delete
  using (user_id = auth.uid() and public.chat_group_visibility(group_id) <> 'direct');

-- 5. Conversations directes -------------------------------------------------------------

create or replace function public.create_direct_conversation(other uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := auth.uid();
  conv uuid;
begin
  if me is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  if other is null or other = me
     or not exists (select 1 from public.profiles where id = other) then
    raise exception 'Destinataire invalide' using errcode = '22023';
  end if;

  -- Réutiliser la conversation existante entre les deux membres.
  select g.id into conv
    from public.chat_groups g
   where g.visibility = 'direct'
     and exists (select 1 from public.chat_group_members m where m.group_id = g.id and m.user_id = me)
     and exists (select 1 from public.chat_group_members m where m.group_id = g.id and m.user_id = other)
     and (select count(*) from public.chat_group_members m where m.group_id = g.id) = 2
   limit 1;

  if conv is null then
    insert into public.chat_groups (name, is_group, visibility, created_by)
    values (null, false, 'direct', me)
    returning id into conv;
    insert into public.chat_group_members (group_id, user_id, member_role)
    values (conv, me, 'member'), (conv, other, 'member');
  end if;

  return conv;
end;
$$;

revoke all on function public.create_direct_conversation(uuid) from public, anon;
grant execute on function public.create_direct_conversation(uuid) to authenticated;
