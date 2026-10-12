# AEEMG Connect

Plateforme numérique de gestion communautaire de l'**Association des Élèves et Étudiants Musulmans de Guinée** :
messagerie, événements, finances, dons, mosquée, rappels islamiques, Coran et calendrier.
Application **Flutter** (Android, iOS, Web) adossée à **Supabase** (PostgreSQL + RLS, Auth, Realtime, Storage, Edge Functions).

## Documentation

| Sujet | Lien |
|---|---|
| Cahier des charges | [docs/CAHIER_DES_CHARGES.md](docs/CAHIER_DES_CHARGES.md) |
| **Rapport d'avancement** | [docs/RAPPORT_AVANCEMENT.md](docs/RAPPORT_AVANCEMENT.md) |
| Backlog (tickets + règles de validité) | [docs/tickets/](docs/tickets/README.md) |
| Décisions d'architecture (ADR) | [docs/adr/](docs/adr/README.md) |
| Règles de travail en équipe | [docs/team/REGLES_EQUIPE.md](docs/team/REGLES_EQUIPE.md) |
| Contribuer | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Intégration continue | [docs/CI.md](docs/CI.md) |
| Sécurité | [SECURITY.md](SECURITY.md) |
| Supabase (installation, auth) | [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md), [docs/SUPABASE_AUTH.md](docs/SUPABASE_AUTH.md) |
| Design system | [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) |
| Administration | [docs/ADMIN_GUIDE.md](docs/ADMIN_GUIDE.md) |

## Structure

```
lib/
  core/       configuration, routing, thème, l10n, utilitaires
  shared/     modèles et widgets partagés (design system : shared/widgets/ds)
  features/   une fonctionnalité par dossier : data/ + presentation/
supabase/
  migrations/ schéma versionné (source de vérité)
  functions/  Edge Functions Deno (SMS, paiements, rappels)
  tests/      tests pgTAP (RLS)
docs/         cahier des charges, ADR, tickets, guides
tool/         scripts (CI, import des tickets)
```

## Démarrage

Voir [CONTRIBUTING.md](CONTRIBUTING.md#démarrage-rapide).

> ⚠️ Avant toute mise en production, traiter les tickets **P0** du backlog (failles RLS, migrations cassées,
> signature Android) — voir l'ordre recommandé dans [docs/tickets/README.md](docs/tickets/README.md#ordre-de-traitement-recommandé).
