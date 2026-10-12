# 0011 — Trois environnements : dev, staging, prod

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : AMEL-013, OPS-003, OPS-005

## Contexte

Un seul projet Supabase sert aujourd'hui au développement, aux tests beta et sert de future production. Les
tests manuels polluent les données réelles et un développeur peut casser la base de tous.

## Décision

| Environnement | Backend | Données | Déploiement |
|---|---|---|---|
| **dev** | Supabase local (`supabase start`, Docker) | `seed.sql` | Poste du développeur |
| **staging** | Projet Supabase dédié | Données fictives | Automatique à chaque merge sur `main` |
| **prod** | Projet Supabase actuel | Réelles | Tag `vX.Y.Z` + approbation manuelle |

Applications : flavors Android `dev`/`staging`/`prod` (suffixe d'ID, nom et icône distincts), web staging sur une URL séparée.

## Conséquences

- ✅ Tests sans risque ; validation en staging avant prod.
- ⚠️ Deuxième projet Supabase (offre gratuite limitée à 2 projets actifs) ; Docker requis en local.

## Vérification

Les secrets de prod n'existent que dans l'environnement GitHub `production` (approbation requise).
