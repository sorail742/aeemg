<!-- Titre de la PR : type(portée): description (ID-TICKET)  ex. feat(finance): saisie des transactions (FEAT-002) -->

## Ticket

Closes #<!-- numéro d'issue --> · Ticket : <!-- ex. SEC-001 -->

## Quoi et pourquoi

<!-- Résumé du changement et de sa raison. Ce qui n'est volontairement PAS fait. -->

## Captures (si UI)

| Avant | Après |
|---|---|
| | |

## Comment tester

1.
2.

## Checklist auteur

- [ ] Les critères d'acceptation du ticket sont tous satisfaits
- [ ] Tests ajoutés/mis à jour (unitaire / widget / pgTAP / Deno) — un bug corrigé a son test de non-régression
- [ ] `dart format`, `flutter analyze` et `flutter test` passent en local
- [ ] Testé sur **Android** et **Web** (iOS si API native touchée)
- [ ] Aucun secret ni donnée personnelle (code, logs, captures)
- [ ] Textes UI en français, messages d'erreur compréhensibles
- [ ] Documentation à jour (README, docs/, CHANGELOG)

## Impacts

- [ ] **Migration SQL** : nouvelle migration uniquement, rejouable, testée par `supabase db reset` — rollback décrit ci-dessous
- [ ] **Sécurité** (RLS, auth, Storage, paiements, données perso) : revue du référent sécurité demandée
- [ ] **ADR** nécessaire / mis à jour : <!-- lien -->
- [ ] **Rupture** pour les versions d'app déjà installées
- [ ] Aucun de ces impacts

<!-- Rollback / notes de déploiement : -->
