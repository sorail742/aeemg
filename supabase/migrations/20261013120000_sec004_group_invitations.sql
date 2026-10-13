-- SEC-004 — Fermer la table group_invitations (fuite de numéros de téléphone)
--
-- Avant (phase7_messaging_fixes.sql) : SELECT using (true) et INSERT with check (true).
-- Un visiteur non connecté pouvait lister tous les numéros invités et en insérer à volonté ;
-- la table était en plus diffusée en Realtime. Pas d'invitant connu, statut libre.
--
-- Après :
--   * invited_by (défaut auth.uid()) ; statut contraint ; numéro au format E.164 ;
--   * lecture : l'invitant, les admins du groupe et le staff (is_group_admin, SEC-003) ;
--   * création : admins du groupe uniquement, en leur propre nom, hors conversations directes ;
--   * aucun droit pour anon ; table retirée de la publication Realtime.
--
-- Les invitations déjà enregistrées n'ont pas d'invitant connu et leurs numéros n'ont jamais
-- été validés : les contraintes invited_by et E.164 sont posées NOT VALID. Elles s'appliquent
-- à toute nouvelle ligne et à toute modification, sans supprimer l'historique.

-- 1. Schéma ------------------------------------------------------------------------------

alter table public.group_invitations
  add column if not exists invited_by uuid references auth.users (id) on delete set null
  default auth.uid();

-- Reprise : l'invitant le plus plausible d'une ancienne invitation est le créateur du groupe.
update public.group_invitations i
   set invited_by = g.created_by
  from public.chat_groups g
 where g.id = i.group_id
   and i.invited_by is null;

alter table public.group_invitations
  drop constraint if exists group_invitations_invited_by_required;
alter table public.group_invitations
  add constraint group_invitations_invited_by_required
  check (invited_by is not null) not valid;

update public.group_invitations
   set status = 'revoked'
 where status not in ('pending', 'accepted', 'expired', 'revoked');

alter table public.group_invitations
  drop constraint if exists group_invitations_status_check;
alter table public.group_invitations
  add constraint group_invitations_status_check
  check (status in ('pending', 'accepted', 'expired', 'revoked'));

alter table public.group_invitations
  drop constraint if exists group_invitations_phone_e164;
alter table public.group_invitations
  add constraint group_invitations_phone_e164
  check (phone_number ~ '^\+[1-9][0-9]{7,14}$') not valid;

-- 2. Droits et policies ------------------------------------------------------------------

revoke all on public.group_invitations from anon;

drop policy if exists "Créer une invitation" on public.group_invitations;
drop policy if exists "Voir les invitations" on public.group_invitations;

drop policy if exists "Invitant et admins du groupe voient les invitations" on public.group_invitations;
create policy "Invitant et admins du groupe voient les invitations"
  on public.group_invitations for select
  using (invited_by = auth.uid() or public.is_group_admin(group_id));

drop policy if exists "Admin du groupe invite un numéro" on public.group_invitations;
create policy "Admin du groupe invite un numéro"
  on public.group_invitations for insert
  with check (
    invited_by = auth.uid()
    and status = 'pending'
    and public.is_group_admin(group_id)
    and public.chat_group_visibility(group_id) in ('public', 'private')
  );

-- Révocation / expiration par un admin du groupe.
drop policy if exists "Admin du groupe gère les invitations" on public.group_invitations;
create policy "Admin du groupe gère les invitations"
  on public.group_invitations for update
  using (public.is_group_admin(group_id))
  with check (public.is_group_admin(group_id));

-- 3. Realtime ----------------------------------------------------------------------------

do $$
begin
  if exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'group_invitations'
  ) then
    alter publication supabase_realtime drop table public.group_invitations;
  end if;
end
$$;
