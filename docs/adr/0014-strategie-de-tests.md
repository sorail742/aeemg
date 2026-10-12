# 0014 — Stratégie de tests (pyramide + pgTAP)

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Tickets liés** : AMEL-007, AMEL-008, OPS-010

## Contexte

6 fichiers de tests pour ~16 700 lignes de Dart, aucun test de base de données ni d'Edge Function. Les failles
RLS et les migrations cassées trouvées par l'audit auraient toutes été détectées par des tests automatiques.

## Décision

| Niveau | Outil | Portée | Où | Exigence |
|---|---|---|---|---|
| Unitaire | `flutter_test` + `mocktail` | Modèles, contrôleurs, utilitaires | `test/` (miroir de `lib/`) | Toute logique nouvelle |
| Widget | `flutter_test` | Écrans et composants | `test/` | Tout écran nouveau ou modifié |
| Golden | `flutter_test` (`matchesGoldenFile`) | Design system | `test/goldens/` | Composants `ds/` |
| Base de données | **pgTAP** (`supabase test db`) | Policies RLS, fonctions, triggers | `supabase/tests/` | **Chaque** policy : cas autorisé + refusé |
| Edge Functions | `deno test` | Handlers, validations, auth | `supabase/functions/**/*_test.ts` | Toute fonction |
| Intégration | `integration_test` | Parcours critiques sur émulateur + Supabase local | `integration_test/` | Parcours listés dans AMEL-007 |
| Manuel | Checklist | Appareils réels, a11y | Description de PR | Toute PR UI |

Règles :
- Couverture minimale globale vérifiée en CI (seuil `COVERAGE_MIN`, 0 % au départ, relevé selon AMEL-007).
- Ordre aléatoire (`--test-randomize-ordering-seed random`) pour détecter les dépendances entre tests.
- Un bug corrigé = un test de non-régression qui échouait avant le correctif.
- Pas d'appel réseau réel dans les tests unitaires/widget.

## Conséquences

- ✅ Les régressions de sécurité deviennent des échecs CI.
- ⚠️ ~20–30 % de temps de développement en plus, compensé par moins de correctifs en production.

## Vérification

Jobs CI `flutter / test`, `supabase / db-tests`, `edge-functions / test` requis sur `main`.
