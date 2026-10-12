# 0006 — Architecture par fonctionnalité (feature-first) en couches

- **Statut** : Accepté
- **Date** : 2026-10-12 (formalisation)
- **Tickets liés** : AMEL-001, AMEL-002, AMEL-003

## Contexte

Le code est déjà organisé en `lib/features/<feature>/{data,presentation}` + `lib/core` + `lib/shared`.
Avec 6 développeurs, cette organisation permet de travailler en parallèle avec peu de conflits — à condition
d'en fixer les règles.

## Décision

```
lib/
  core/        # transverse technique : config, router, thème, l10n, utilitaires, providers globaux
  shared/      # widgets et modèles réutilisés par ≥ 2 features (design system dans shared/widgets/ds)
  features/<f>/
    data/          # repositories, sources (Supabase, cache), modèles (DTO)
    domain/        # (optionnel) entités et règles métier pures, sans Flutter ni Supabase
    presentation/  # écrans, widgets, providers/contrôleurs
```

Règles de dépendance :
1. `presentation` → `data`/`domain` ; jamais l'inverse.
2. Une feature n'importe pas le `presentation` d'une autre feature (passer par `shared/` ou la navigation).
3. `core` et `shared` n'importent aucune feature (exception temporaire : `core/router`).
4. Fichier ≤ 400 lignes ; widget ≤ 150 lignes de `build` (sinon extraire).

## Conséquences

- ✅ Propriété claire par feature (CODEOWNERS), revues ciblées, moins de conflits.
- ⚠️ Discipline nécessaire pour les éléments partagés ; refactor des écrans existants (AMEL-001).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Couches globales (`lib/screens`, `lib/services`) | Conflits fréquents, couplage entre features |
| Clean Architecture stricte (use cases partout) | Trop de cérémonie pour la taille de l'équipe ; `domain/` reste optionnel |

## Vérification

Job CI `maintainability` (taille des fichiers) ; règle d'import vérifiée par script à partir d'AMEL-002.
