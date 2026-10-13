-- SEC-008 — Empêcher la falsification du statut des dons et des sessions de paiement
--
-- Avant :
--   * donations : policy « Créer un don » = `auth.uid() = user_id` sans contrainte sur status :
--     un membre pouvait insérer directement un don `completed` (statistiques, campagnes) ;
--   * payment_sessions : insertion directe par le client avec n'importe quel status / amount.
--
-- Après :
--   * un membre ne crée que des dons `pending` ;
--   * les dons payés par mobile money ne changent de statut que par le service role (webhook
--     de paiement, FEAT-004) ; le trésorier enregistre et valide les dons en espèces (`cash`) ;
--   * transitions autorisées par l'API : pending → completed | failed ; montant, donateur,
--     campagne et moyen de paiement ne sont plus modifiables par un client ;
--   * payment_sessions n'est plus alimentée que par l'Edge Function (service role) ;
--   * historique des statuts dans donation_status_history.
--
-- La modification des payment_sessions par le staff relève de SEC-009.

-- 1. Création des dons -------------------------------------------------------------------

drop policy if exists "Créer un don" on public.donations;
drop policy if exists "Créer un don en attente" on public.donations;
create policy "Créer un don en attente"
  on public.donations for insert
  with check (auth.uid() = user_id and status = 'pending');

-- Dons en espèces reçus en main propre : le trésorier les enregistre, déjà confirmés ou non.
drop policy if exists "Trésorier enregistre un don en espèces" on public.donations;
create policy "Trésorier enregistre un don en espèces"
  on public.donations for insert
  with check (public.is_treasurer() and payment_method = 'cash');

-- 2. Changements de statut ---------------------------------------------------------------

-- Le trésorier (hors is_staff) doit voir les dons pour les valider et tenir les comptes.
drop policy if exists "Trésorier voit les dons" on public.donations;
create policy "Trésorier voit les dons"
  on public.donations for select
  using (public.is_treasurer());

drop policy if exists "Trésorier valide un don en espèces" on public.donations;
create policy "Trésorier valide un don en espèces"
  on public.donations for update
  using (public.is_treasurer() and payment_method = 'cash')
  with check (public.is_treasurer() and payment_method = 'cash');

create or replace function public.guard_donation_update()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  -- Appels par l'API (clients et service role) ; une correction manuelle en SQL
  -- (rôle postgres) reste possible.
  if current_user in ('authenticated', 'anon', 'service_role')
     and old.status is distinct from new.status
     and not (old.status = 'pending' and new.status in ('completed', 'failed')) then
    raise exception 'Transition de statut interdite : % → %', old.status, new.status
      using errcode = '42501';
  end if;

  -- Les clients ne modifient que le statut ; le service role reste libre (webhook).
  if current_user in ('authenticated', 'anon')
     and (new.amount is distinct from old.amount
          or new.user_id is distinct from old.user_id
          or new.campaign_id is distinct from old.campaign_id
          or new.payment_method is distinct from old.payment_method
          or new.category is distinct from old.category
          or new.is_anonymous is distinct from old.is_anonymous
          or new.created_at is distinct from old.created_at) then
    raise exception 'Seul le statut d''un don peut être modifié'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists donations_guard_update on public.donations;
create trigger donations_guard_update
  before update on public.donations
  for each row execute function public.guard_donation_update();

-- 3. Historique des statuts --------------------------------------------------------------

create table if not exists public.donation_status_history (
  id bigint generated always as identity primary key,
  donation_id uuid not null references public.donations (id) on delete cascade,
  old_status public.donation_status,
  new_status public.donation_status not null,
  changed_by uuid references auth.users (id) on delete set null,
  -- Rôle JWT de l'appel (authenticated, service_role…) ; null hors API (SQL direct).
  changed_via text,
  changed_at timestamptz not null default now()
);

create index if not exists donation_status_history_donation_idx
  on public.donation_status_history (donation_id, changed_at);

alter table public.donation_status_history enable row level security;

-- Lecture : le donateur et le trésorier. Aucune écriture client : seul le trigger écrit.
drop policy if exists "Historique des dons lisible par le donateur et le trésorier"
  on public.donation_status_history;
create policy "Historique des dons lisible par le donateur et le trésorier"
  on public.donation_status_history for select
  using (
    public.is_treasurer()
    or exists (
      select 1 from public.donations d
       where d.id = donation_status_history.donation_id and d.user_id = auth.uid()
    )
  );

create or replace function public.log_donation_status()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    insert into public.donation_status_history
      (donation_id, old_status, new_status, changed_by, changed_via)
    values (
      new.id,
      case when tg_op = 'UPDATE' then old.status end,
      new.status,
      auth.uid(),
      coalesce(
        nullif(current_setting('request.jwt.claim.role', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists donations_log_status on public.donations;
create trigger donations_log_status
  after insert or update of status on public.donations
  for each row execute function public.log_donation_status();

-- Point de départ de l'historique pour les dons existants.
insert into public.donation_status_history (donation_id, old_status, new_status, changed_at)
select d.id, null, d.status, d.created_at
  from public.donations d
 where not exists (
   select 1 from public.donation_status_history h where h.donation_id = d.id
 );

-- 4. Sessions de paiement ----------------------------------------------------------------

-- Créées uniquement par l'Edge Function orange-money-init (service role).
drop policy if exists "Creer session paiement" on public.payment_sessions;
