-- SEC-017 — Restreindre la modification des messages
--
-- Contexte :
--   Policy "Modifier ses propres messages" (phase7) : l'expéditeur pouvait modifier
--   toutes les colonnes, y compris group_id (déplacement dans un autre groupe),
--   is_pinned (réservé aux modérateurs selon le CDC §3.1) et created_at.
--
-- Actions :
--   1. Remplacer la policy de mise à jour pour autoriser l'expéditeur ou un modérateur/admin du groupe.
--   2. Créer le trigger BEFORE UPDATE public.guard_message_update() qui garantit :
--      - L'immuabilité stricte des métadonnées (id, group_id, sender_id, created_at, message_type, media_url, media_path, reply_to_id).
--      - La modification de content réservée à l'expéditeur dans une fenêtre de 15 minutes.
--      - La modification de is_pinned réservée aux modérateurs / admins du groupe (is_group_admin).
--      - La suppression logique (is_deleted) réservée à l'expéditeur ou modérateur/admin.

-- 1. RLS UPDATE sur public.messages -------------------------------------------------------

drop policy if exists "Modifier ses propres messages" on public.messages;
drop policy if exists "Modifier ou epingler un message" on public.messages;

create policy "Modifier ou epingler un message"
  on public.messages for update
  to authenticated
  using (
    auth.uid() = sender_id
    or public.is_group_admin(group_id)
  )
  with check (
    auth.uid() = sender_id
    or public.is_group_admin(group_id)
  );

-- 2. Trigger de protection des colonnes ---------------------------------------------------

create or replace function public.guard_message_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_is_sender boolean;
  v_is_admin boolean;
begin
  -- Les opérations directes en base (rôle postgres/superuser) ne sont pas bloquées
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  v_is_sender := (auth.uid() = old.sender_id);
  v_is_admin := public.is_group_admin(old.group_id);

  -- 1. Colonnes strictement immuables
  if new.id is distinct from old.id
     or new.group_id is distinct from old.group_id
     or new.sender_id is distinct from old.sender_id
     or new.created_at is distinct from old.created_at
     or new.message_type is distinct from old.message_type
     or new.media_url is distinct from old.media_url
     or new.media_path is distinct from old.media_path
     or new.reply_to_id is distinct from old.reply_to_id then
    raise exception 'Colonne protégée de messages : modification interdite (SEC-017)'
      using errcode = '42501';
  end if;

  -- 2. Épinglage (is_pinned) : réservé au modérateur ou admin du groupe
  if new.is_pinned is distinct from old.is_pinned then
    if not v_is_admin then
      raise exception 'Seul un modérateur ou administrateur du groupe peut modifier l''épinglage (SEC-017)'
        using errcode = '42501';
    end if;
  end if;

  -- 3. Contenu (content) : réservé à l'expéditeur dans une fenêtre de 15 minutes
  if new.content is distinct from old.content then
    if not v_is_sender then
      raise exception 'Seul l''expéditeur peut modifier le contenu de son message (SEC-017)'
        using errcode = '42501';
    end if;

    if now() > old.created_at + interval '15 minutes' then
      raise exception 'Le délai de 15 minutes pour modifier le message est expiré (SEC-017)'
        using errcode = '42501';
      end if;
  end if;

  -- 4. Suppression logique (is_deleted) : réservée à l'expéditeur ou modérateur/admin
  if new.is_deleted is distinct from old.is_deleted then
    if not (v_is_sender or v_is_admin) then
      raise exception 'Seul l''expéditeur ou un modérateur peut supprimer un message (SEC-017)'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

comment on function public.guard_message_update() is
  'Protège les colonnes de messages : immuabilité des métadonnées, fenêtre de 15 min pour content, is_pinned réservé aux admins du groupe (SEC-017).';

drop trigger if exists messages_guard_update on public.messages;
create trigger messages_guard_update
  before update on public.messages
  for each row execute function public.guard_message_update();
