# 0008 — Modèle de rôles et matrice de permissions

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : SEC-001, SEC-021, DEL-007, FEAT-018, FEAT-035

## Contexte

L'enum `user_role` contient 9 valeurs (dont `staff`, ajouté en phase 9 en contradiction avec le reste).
Les helpers SQL et le modèle Dart ne s'accordent pas, et des policies recopient des listes de rôles différentes.
Le CDC (§5) définit 8 rôles.

## Décision

Rôle **global** unique par profil, modifiable uniquement via la RPC `set_member_role` :

| Capacité | super_admin | admin | moderator | treasurer | section_lead | member | volunteer | visitor |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Configurer, attribuer admin/super_admin | ✅ | | | | | | | |
| Attribuer les autres rôles, supprimer un membre | ✅ | ✅ | | | | | | |
| Annonces, événements (tous), groupes officiels | ✅ | ✅ | | | | | | |
| Événements de sa section (proposition) | ✅ | ✅ | | | ✅ | | | |
| Modérer messages/posts, valider adhésions | ✅ | ✅ | ✅ | | ✅ (sa section) | | | |
| Saisir transactions, valider dons espèces | ✅ | | | ✅ | | | | |
| Consulter rapports financiers non publiés | ✅ | ✅ | | ✅ | | | | |
| Publier les bilans | ✅ | ✅ | | | | | | |
| Messagerie, RSVP, dons, social | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Missions de bénévolat | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Contenus publics, formulaire d'adhésion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Helpers SQL (seule source de vérité, répliqués à l'identique dans `Profile` côté Dart) :
`is_super_admin()`, `is_admin()` (super_admin, admin), `is_moderator()` (+ moderator, section_lead),
`is_treasurer()` (super_admin, treasurer), `is_member()` (tout sauf visitor).

Le rôle `staff` est déprécié (DEL-007). Les rôles **de groupe** de messagerie (owner/admin/member) sont
distincts et stockés dans `chat_group_members` (SEC-003).

## Conséquences

- ✅ Une matrice testable cellule par cellule ; plus d'incohérences SQL/Dart.
- ⚠️ `admin` perd l'accès en écriture aux finances (séparation des pouvoirs) : à valider par le bureau.
- 🔧 Migration des profils `staff`, réécriture des policies (SEC-021).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Permissions fines (table `role_permissions`) | Sur-dimensionné pour 8 rôles ; à reconsidérer si multi-associations |
| Rôles multiples par utilisateur | Complexité RLS ; un trésorier qui est aussi modérateur est rare → rôle principal |

## Vérification

Tests pgTAP par cellule critique ; test unitaire Dart vérifiant que `Profile` reproduit les helpers.
