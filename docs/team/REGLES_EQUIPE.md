# Règles de travail en équipe — AEEMG Connect

Équipe de **6 personnes**. Ces règles s'appliquent à tous, Tech Lead compris. Elles peuvent être modifiées
par PR sur ce fichier, approuvée par au moins 4 membres sur 6 (décision prise en rétrospective).

---

## 1. Rôles et responsabilités

| # | Rôle | Responsabilités principales | Domaines (owner principal) | Suppléant |
|---|---|---|---|---|
| 1 | **Tech Lead / Architecte** | ADR, arbitrages techniques, revue finale des PR sensibles, release manager, protège la qualité | `lib/core/`, `docs/adr/`, releases | Dev 4 |
| 2 | **Dev Flutter — Communication** | Messagerie, social, notifications, annonces | `features/messages`, `social`, `notifications` | Dev 3 |
| 3 | **Dev Flutter — Communauté** | Événements, agenda, membres, profil, contenu islamique, Coran | `features/events`, `agenda`, `members`, `profile`, `islamic`, `quran`, `hadith` | Dev 2 |
| 4 | **Dev Backend Supabase** | Schéma, migrations, RLS, pgTAP, Edge Functions, intégrations SMS/paiement | `supabase/**` | Dev 1 |
| 5 | **Dev Full-stack — Gestion** | Finances, dons, mosquée, administration | `features/finance`, `donations`, `mosque`, `admin` | Dev 4 |
| 6 | **QA / DevOps** | CI/CD, stratégie de tests, recette, builds stores, supervision, accessibilité | `.github/**`, `test/`, `integration_test/`, `tool/` | Dev 1 |

Rôles transverses :
- **Product Owner** : représentant du bureau AEEMG (hors équipe de dev), priorise le backlog, valide les démos.
  En son absence, le Tech Lead arbitre les priorités **techniques** uniquement.
- **Facilitateur (Scrum Master)** : tournant à chaque sprint parmi les 6 (anime les rituels, suit les blocages).
- **Référent sécurité** : Dev 4 + Tech Lead — revue obligatoire de toute PR touchant auth, RLS, Storage, paiements, données personnelles.
- **Référent contenu religieux** : personne désignée par le bureau ; valide tout contenu islamique avant publication (CDC §8).

> **Règle anti-bus-factor** : chaque domaine a un owner **et** un suppléant qui fait au moins une PR par sprint
> dans ce domaine. Personne n'est seul à connaître une partie du code.

## 2. Organisation du travail (Scrum allégé)

- **Sprint de 2 semaines**, du lundi au vendredi de la 2e semaine.
- **Capacité** : ~20 % de chaque sprint réservés à la dette technique (`AMEL`, `DEL`, `REL`), ~10 % au support/bugs.
- Les tickets `P0` passent devant tout, y compris en cours de sprint.

| Rituel | Quand | Durée | Contenu |
|---|---|---|---|
| Daily | Chaque jour ouvré, 9 h 00 (ou asynchrone dans le canal `#daily` avant 10 h) | 15 min max | Hier / aujourd'hui / blocages. Les discussions longues se font après. |
| Affinage du backlog | Mercredi semaine 1 | 1 h | Tickets mis au niveau de la Definition of Ready, estimations |
| Planification | Lundi début de sprint | 1 h 30 | Objectif du sprint + tickets engagés (≤ capacité) |
| Revue / démo | Vendredi fin de sprint | 1 h | Démo **sur l'app réelle (staging)** au PO ; pas de slides |
| Rétrospective | Vendredi fin de sprint | 45 min | 1 à 3 actions d'amélioration, avec un responsable chacune |

Les horaires des réunions évitent les heures de prière (prévoir une marge autour de Dhuhr et Asr) et le vendredi midi.

## 3. Tickets

- **Aucun travail sans ticket.** Une découverte en cours de route → nouveau ticket, pas d'élargissement silencieux.
- Format et règles de validité : [docs/tickets/README.md](../tickets/README.md) (DoR, DoD).
- On s'**assigne** un ticket en le déplaçant dans « In progress » ; **maximum 2 tickets en cours** par personne (WIP limit).
- Un ticket bloqué plus d'une journée reçoit le label `blocked` et est signalé au daily.
- Estimation en tailles T-shirt ; un ticket `XL` est découpé avant d'entrer en sprint.

## 4. Git et branches

Résumé de l'[ADR-0021](../adr/0021-workflow-git.md) :

- `main` protégée : aucun push direct, PR obligatoire, CI verte obligatoire.
- Branche : `<type>/<ID-ticket>-<description>` — ex. `sec/SEC-001-role-escalation`, `feat/FEAT-002-transactions`.
  Types : `feat`, `fix`, `sec`, `refactor`, `perf`, `test`, `docs`, `ci`, `chore`, `hotfix`.
- Durée de vie d'une branche ≤ 3 jours ; au-delà, découper ou utiliser un feature flag.
- Commits : [Conventional Commits](https://www.conventionalcommits.org/fr/) en français ou anglais (cohérent dans une PR).
- **Titre de PR** = message du commit final (squash) : `feat(finance): saisie des transactions (FEAT-002)`.
- Interdits : `git push --force` sur `main` ou sur la branche d'un autre ; commit de fichiers générés de build, de `.env`, de keystores.

## 5. Pull Requests et revue de code

### Auteur
- PR **petite** : ≤ 400 lignes modifiées (hors générés) ; au-delà, justification dans la description.
- Remplit le modèle de PR (lien ticket, captures avant/après pour l'UI, plan de test, impact sécurité/migration).
- Relit lui-même son diff avant de demander une revue ; CI verte avant de solliciter les relecteurs.
- Ouvre la PR en **Draft** tant qu'elle n'est pas prête.
- Répond à **chaque** commentaire (correction ou explication) ; c'est le relecteur qui résout la conversation.

### Relecteurs
- **2 approbations** requises, dont **1 CODEOWNER** du domaine. PR touchant `supabase/**`, l'auth, les paiements
  ou les données personnelles : approbation du **référent sécurité** obligatoire.
- **Délai de première revue : 1 jour ouvré.** Chacun commence sa journée par les revues en attente.
- Commentaires préfixés : `bloquant:`, `question:`, `suggestion:`, `nit:` (détail non bloquant), `bravo:`.
- On critique le code, jamais la personne. On propose une alternative concrète.
- Checklist du relecteur :
  - [ ] Le code fait ce que dit le ticket, et seulement cela
  - [ ] Tests pertinents (cas nominal + cas d'erreur + cas refusé pour la RLS)
  - [ ] Pas de secret, pas de donnée personnelle dans les logs
  - [ ] Erreurs gérées et messages utilisateur en français
  - [ ] Respect des ADR (architecture, état, navigation, migrations)
  - [ ] Fonctionne sur Android **et** Web (ou dégradation propre documentée)
  - [ ] Accessibilité de base (libellés, contraste, tailles)

### Merge
- Par l'**auteur**, en **squash**, une fois les approbations et la CI obtenues. Suppression de la branche après merge.
- Un relecteur n'approuve pas une PR qu'il n'a pas réellement lue ou testée quand c'est nécessaire.

## 6. Qualité et standards de code

- Respect de l'[ADR-0006](../adr/0006-architecture-feature-first.md) (architecture), [ADR-0004](../adr/0004-riverpod-gestion-etat.md) (état), [ADR-0007](../adr/0007-rls-frontiere-de-securite.md) (sécurité).
- `dart format` + `flutter analyze` sans avertissement avant chaque push (hooks locaux : OPS-012).
- Nommage : fichiers `snake_case.dart`, classes `PascalCase`, providers `xxxProvider`, tables SQL `snake_case` au pluriel.
- Pas de `print` (utiliser le logger), pas de `// ignore:` sans commentaire justificatif et ticket.
- Tout `TODO` référence un ticket : `// TODO(FEAT-009): ...`.
- Un bug corrigé est accompagné d'un test de non-régression.
- Migrations : jamais modifier une migration mergée ([ADR-0010](../adr/0010-migrations-versionnees.md)).

## 7. Sécurité et données

- **Secrets** : jamais dans le dépôt, les tickets, les captures ou les messages. Gestion via GitHub Secrets et secrets
  Supabase. Une fuite = rotation immédiate + signalement au Tech Lead (même en cas de doute).
- **Accès production** (Dashboard Supabase prod, clés stores, keystore) : **2 personnes** seulement (Tech Lead + Dev 4)
  + un membre du bureau ; accès nominatifs, 2FA obligatoire sur GitHub, Supabase, Google Play, Apple.
- **Données des membres** : pas d'export de la base prod sur un poste personnel ; données fictives en dev/staging.
- Vulnérabilités : procédure de [SECURITY.md](../../SECURITY.md) ; aucune discussion publique avant correctif.

## 8. Communication

| Canal | Usage |
|---|---|
| GitHub (issues, PR) | Source de vérité des décisions techniques ; toute décision prise ailleurs y est reportée |
| Groupe d'équipe (WhatsApp/Discord/Slack) | Coordination rapide, `#daily`, `#revues`, `#incidents` |
| Réunion | Rituels, décisions bloquantes |

- Réponse attendue sous **1 jour ouvré** ; un message urgent (incident prod, P0) est explicitement marqué `URGENT`.
- Absences et indisponibilités (examens, voyages) annoncées au plus tôt dans le canal d'équipe et le planning de sprint.
- Langue : français pour la documentation, les tickets et l'UI ; identifiants de code en anglais.

## 9. Prise de décision et désaccords

1. Discussion argumentée dans la PR/l'issue (données, liens, prototypes plutôt qu'opinions).
2. Désaccord persistant après 2 échanges → appel synchrone de 15 min entre les personnes concernées.
3. Toujours bloqué → le **Tech Lead** tranche pour la technique, le **PO** pour le fonctionnel ; la décision est consignée (ADR si structurante).
4. « Désaccord mais engagement » : une fois tranché, tout le monde applique la décision.

## 10. Incidents de production

- Toute personne qui constate un incident ouvre une issue `incident` (P0) et prévient dans `#incidents`.
- Un **responsable d'incident** (le premier disponible parmi les owners du domaine) coordonne ; les autres aident sur demande.
- Priorité : rétablir le service (rollback, désactivation de fonctionnalité) avant de corriger.
- Post-mortem **sans recherche de coupable** dans `docs/runbooks/postmortems/` sous 5 jours ouvrés, avec actions → tickets.

## 11. Arrivée d'un nouveau membre

- [ ] Accès GitHub (équipe correspondante), 2FA activée
- [ ] Lecture : README, CONTRIBUTING, ce document, ADR acceptés, cahier des charges
- [ ] Environnement local fonctionnel (Flutter version figée, Supabase CLI, Docker, Deno) — objectif < 1/2 journée
- [ ] Premier ticket `good-first-issue` en binôme avec le suppléant du domaine
- [ ] Ajout dans CODEOWNERS après 3 PR mergées dans le domaine

## 12. Bien-être et respect

- Pas de messages de travail attendus en dehors de 8 h–20 h ni pendant les examens annoncés.
- Respect mutuel, des convictions et des temps de prière ; propos discriminants ou irrespectueux non tolérés.
- On célèbre les livraisons en revue de sprint 🎉.
