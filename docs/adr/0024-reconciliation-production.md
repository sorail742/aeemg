# 0024 — Réconcilier la production avec l'historique des migrations

- **Statut** : Accepté
- **Date** : 2026-10-13
- **Décideurs** : Mainteneur du dépôt (demande d'appliquer les correctifs de sécurité en production)
- **Complète** : [ADR-0010](./0010-migrations-versionnees.md), [ADR-0022](./0022-migrations-historiques-rejouables.md)
- **Tickets liés** : REL-001, REL-002, SEC-001, SEC-003, SEC-004, SEC-006, SEC-008

## Contexte

La base de production (`fuumkjatgczkbxdpjduo`) a été construite à la main (`APPLY_ALL.sql`, éditeur
SQL du Dashboard) : aucun historique `supabase_migrations`, et un schéma qui diverge de l'état « après
phase 9 » des migrations. Une comparaison d'empreinte (tables, colonnes, contraintes, policies,
fonctions, triggers, enums, publication Realtime) faite le 2026-10-13 a relevé 68 écarts :

- phase 4 absente (`payment_sessions`, `sms_notifications`, 2 enums, 2 colonnes) ;
- phases 8/9 partielles (valeur d'enum `staff`, 3 policies `Staff can … events`, FK
  `donations.user_id` sans `ON DELETE SET NULL`) ;
- 18 policies au nom sans accents (définitions identiques) et 2 doublons « v2 » identiques.

Les migrations de sécurité suppriment les anciennes policies par leur nom accentué : appliquées telles
quelles, elles auraient laissé actives les policies permissives (`Creer un don`…), sans erreur.

## Décision

1. Une migration **idempotente** `20260615000000_reconciliation_production.sql` amène la production à
   l'état « après phase 9 ». Sur une base construite par les migrations, elle ne change rien ; le job
   `supabase / db` le vérifie à chaque PR.
2. L'historique de production est initialisé en marquant appliquées les 13 migrations historiques
   (équivalent `supabase migration repair --status applied`), puis les migrations suivantes sont
   appliquées normalement (`supabase db push`).
3. Avant d'appliquer, la procédure est rejouée sur une **réplique locale** de la production (état
   phase 9 + écarts mesurés + données de même forme) ; l'empreinte finale doit être identique à
   celle d'une base neuve.
4. La fonction `join_default_chat_group` de production cherche le groupe `General AEEMG` (nom réel
   en production) : elle est conservée telle quelle.

## Conséquences

- ✅ `supabase db push` devient l'unique voie de modification du schéma de production.
- ✅ Les correctifs de sécurité s'appliquent réellement (plus de policy permissive résiduelle).
- ⚠️ Toute modification manuelle future en production réintroduit une dérive : interdite (ADR-0010).
- ⚠️ Le plan gratuit n'offre pas les branches Supabase : la validation se fait sur la réplique locale
  et dans le job `supabase / db`.
