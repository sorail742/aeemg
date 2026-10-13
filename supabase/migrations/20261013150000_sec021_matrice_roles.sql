-- SEC-021 — Une seule matrice de rôles (ADR-0008)
--
-- Avant :
--   * la phase 9 a ajouté la valeur d'enum `staff` et trois policies « Staff can … events »
--     (`role in ('admin', 'staff')`) qui ignorent super_admin, moderator et section_lead, alors
--     que is_staff() et le modèle Dart ignorent `staff` ;
--   * les événements avaient donc deux policies par opération (« Staff crée des événements »
--     + « Staff can create events », idem update et delete).
--
-- Après :
--   * une seule policy par (table, opération, intention) sur events, fondée sur is_staff() ;
--   * `staff` est déprécié : les profils existants deviennent `moderator` et la valeur ne peut
--     plus être attribuée (une valeur d'enum ne se supprime pas sans recréer le type) ;
--   * la matrice est documentée dans docs/ADMIN_GUIDE.md et testée (pgTAP + test Dart).

-- 1. Doublons sur events -----------------------------------------------------------------

drop policy if exists "Staff can create events" on public.events;
drop policy if exists "Staff can update events" on public.events;
drop policy if exists "Staff can delete events" on public.events;

-- 2. Dépréciation de `staff` ---------------------------------------------------------------

-- Exécuté en tant que propriétaire : le trigger protect_profile_columns laisse passer.
update public.profiles set role = 'moderator' where role::text = 'staff';

alter table public.profiles drop constraint if exists profiles_role_not_staff;
alter table public.profiles add constraint profiles_role_not_staff
  check (role::text <> 'staff');

comment on type public.user_role is
  'Rôle global (ADR-0008). La valeur staff est dépréciée (SEC-021) et refusée par '
  'la contrainte profiles_role_not_staff.';
