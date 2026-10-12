# Backlog AEEMG Connect — Tickets

Backlog issu de l'audit complet du dépôt (code Flutter, migrations Supabase,
Edge Functions, CI, docs, cahier des charges v1.1) réalisé en octobre 2026.

Chaque ticket est **autonome** : contexte (avec fichiers concernés), travail
attendu, **critères d'acceptation** (règles de validité, vérifiables) et
dépendances. Un ticket n'est « Terminé » que si ses critères **et** la
[Definition of Done](#definition-of-done-dod-globale) sont satisfaits.

## Fichiers

| Fichier | Préfixe | Contenu | Nb |
|---|---|---|---|
| [01-securite.md](./01-securite.md) | `SEC` | Failles RLS, Storage, Edge Functions, données perso, release | 26 |
| [02-fiabilite-robustesse.md](./02-fiabilite-robustesse.md) | `REL` | Build cassé, migrations cassées, idempotence, intégrité, erreurs | 16 |
| [03-suppressions.md](./03-suppressions.md) | `DEL` | Code mort, doublons, fichiers à retirer | 12 (dont 1 livré) |
| [04-ameliorations.md](./04-ameliorations.md) | `AMEL` | Architecture, perf, compatibilité, i18n, a11y, tests | 25 |
| [05-fonctionnalites.md](./05-fonctionnalites.md) | `FEAT` | Fonctionnalités du cahier des charges non implémentées | 43 |
| [06-devops-qualite.md](./06-devops-qualite.md) | `OPS` | CI/CD, environnements, observabilité, release | 14 |

Import dans GitHub Issues : `python3 tool/create_github_issues.py --dry-run`
puis sans `--dry-run` (nécessite `gh auth login`). Le script crée un label
par type/priorité et ne recrée pas un ticket dont l'ID existe déjà.

## Format d'un ticket

```markdown
### SEC-001 — Titre court à l'impératif
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/db
**Dépendances** : REL-001

**Contexte** — Constat + fichiers/lignes concernés.
**Travail attendu** — Ce qu'il faut faire (pas forcément comment).
**Critères d'acceptation**
- [ ] Règle vérifiable 1 (test automatisé de préférence)
- [ ] Règle vérifiable 2
```

## Priorités

| Priorité | Signification | Délai cible |
|---|---|---|
| **P0** | Bloquant : faille exploitable, perte de données, déploiement impossible | Sprint en cours, avant toute mise en production |
| **P1** | Majeur : fonctionnalité cœur cassée/absente, risque élevé | Sprint suivant |
| **P2** | Important : dette, qualité, fonctionnalité secondaire | Dans le trimestre |
| **P3** | Confort / nice-to-have | Quand capacité disponible |

## Estimation (taille T-shirt)

| Taille | Effort indicatif |
|---|---|
| XS | < 2 h |
| S | ½ journée |
| M | 1–2 jours |
| L | 3–5 jours |
| XL | > 1 semaine → **doit être découpé** avant d'entrer en sprint |

## Labels GitHub

- Type : `type:securite`, `type:fiabilite`, `type:suppression`, `type:amelioration`, `type:fonctionnalite`, `type:devops`, `type:bug`
- Priorité : `P0`, `P1`, `P2`, `P3`
- Composant : `comp:flutter`, `comp:supabase-db`, `comp:edge-functions`, `comp:ci`, `comp:docs`, `comp:android`, `comp:ios`, `comp:web`
- État : `needs-triage`, `ready`, `blocked`, `needs-adr`

## Definition of Ready (DoR)

Un ticket peut entrer dans un sprint seulement si :

- [ ] Le titre et le contexte sont compréhensibles par n'importe quel membre de l'équipe
- [ ] Les critères d'acceptation sont **testables** (pas de « ça marche bien »)
- [ ] La priorité et l'estimation sont fixées ; taille ≤ L
- [ ] Les dépendances sont identifiées et non bloquantes (ou planifiées avant)
- [ ] Si le ticket change l'architecture, le schéma de données ou un choix technique durable : un ADR est rédigé ou référencé (`needs-adr`)
- [ ] Les maquettes sont jointes si le ticket touche l'UI

## Definition of Done (DoD) globale

S'applique à **tous** les tickets en plus de leurs critères propres :

- [ ] Code mergé dans `main` via PR approuvée (cf. [règles d'équipe](../team/REGLES_EQUIPE.md))
- [ ] Toute la CI requise est verte (format, analyse, tests, sécurité, compatibilité, migrations)
- [ ] Tests automatisés ajoutés/ajustés : unitaire pour la logique, widget pour l'UI, pgTAP pour toute policy RLS ou fonction SQL
- [ ] Aucune régression de couverture de tests sur les fichiers modifiés
- [ ] Toute modification de schéma passe par une **nouvelle** migration horodatée (jamais d'édition d'une migration déjà appliquée)
- [ ] Aucun secret, clé ou donnée personnelle dans le code, les logs ou les captures
- [ ] Textes UI en français via le système i18n (pas de chaîne en dur une fois AMEL-005 livré)
- [ ] Documentation mise à jour (README, docs/, ADR, CHANGELOG)
- [ ] Testé manuellement sur Android **et** Web (et iOS si le ticket touche une API native)
- [ ] Le ticket est fermé avec un lien vers la PR

## Ordre de traitement recommandé

1. **Sprint 0 — Assainissement (bloquant prod)** : REL-016, REL-001, REL-002, SEC-001, SEC-003, SEC-004, SEC-006, SEC-008, SEC-010, SEC-020, OPS-001, OPS-002
2. **Sprint 1 — Sécurité & fiabilité** : reste des `SEC` P1, REL-004/005/007/012, AMEL-011, AMEL-012, DEL-001
3. **Sprint 2 — Conformité stores** : FEAT-037, FEAT-038, FEAT-043, FEAT-001, SEC-022, SEC-025
4. **Sprints suivants** : `FEAT` par module (Finances → Dons → Événements → Membres → Mosquée → Islamique), `AMEL` en continu (≈ 20 % de la capacité de chaque sprint réservée à la dette)
