# Architecture Decision Records (ADR)

Un ADR documente **une** décision d'architecture ou technique durable : son
contexte, la décision, ses conséquences et les alternatives rejetées. Il permet
à une équipe de 6 personnes (et aux suivantes) de comprendre *pourquoi* le
projet est ainsi, sans dépendre de la mémoire de quelqu'un.

## Quand écrire un ADR ?

Obligatoire si la PR :
- ajoute/retire une dépendance structurante (paquet de state management, routing, SDK tiers, fournisseur SMS/paiement…) ;
- change le schéma de sécurité (RLS, rôles, auth, stockage) ;
- change l'architecture des dossiers, la stratégie de tests, de CI/CD ou de release ;
- introduit un nouveau service externe ou un coût récurrent.

## Processus

1. Copier [`0000-template.md`](./0000-template.md) en `NNNN-titre-en-kebab-case.md` (numéro suivant).
2. Statut `Proposé`, ouvrir une PR **dédiée** avec le label `needs-adr`.
3. Discussion dans la PR ; au moins **3 approbations dont le Tech Lead**.
4. Au merge : statut `Accepté` (ou `Rejeté` — un ADR rejeté est conservé).
5. Un ADR accepté n'est **jamais réécrit** : on en crée un nouveau qui le
   `Remplace`, et l'ancien passe à `Remplacé par NNNN`.

## Index

| N° | Titre | Statut |
|---|---|---|
| [0001](./0001-enregistrer-les-decisions.md) | Enregistrer les décisions d'architecture | Accepté |
| [0002](./0002-flutter-multiplateforme.md) | Flutter pour Android, iOS et Web (desktop exclu) | Accepté |
| [0003](./0003-supabase-backend.md) | Supabase comme backend unique | Accepté |
| [0004](./0004-riverpod-gestion-etat.md) | Riverpod pour l'injection et la gestion d'état | Accepté |
| [0005](./0005-go-router-navigation.md) | go_router pour la navigation et les deep links | Accepté |
| [0006](./0006-architecture-feature-first.md) | Architecture par fonctionnalité (feature-first) en couches | Accepté |
| [0007](./0007-rls-frontiere-de-securite.md) | La RLS PostgreSQL est la frontière de sécurité | Accepté |
| [0008](./0008-modele-de-roles.md) | Modèle de rôles et matrice de permissions | Proposé |
| [0009](./0009-configuration-par-dart-define.md) | Configuration par `--dart-define-from-file` | Proposé |
| [0010](./0010-migrations-versionnees.md) | Migrations SQL versionnées via Supabase CLI | Accepté |
| [0011](./0011-environnements.md) | Trois environnements : dev, staging, prod | Proposé |
| [0012](./0012-notifications-push.md) | Notifications push via FCM HTTP v1 depuis une Edge Function | Proposé |
| [0013](./0013-internationalisation.md) | Internationalisation avec `gen-l10n` (FR, Peul, Arabe) | Proposé |
| [0014](./0014-strategie-de-tests.md) | Stratégie de tests (pyramide + pgTAP) | Accepté |
| [0015](./0015-paiements-mobile-money.md) | Paiements mobile money pilotés par webhooks idempotents | Proposé |
| [0016](./0016-versionnage-et-releases.md) | SemVer, Conventional Commits et releases par tag | Accepté |
| [0017](./0017-observabilite.md) | Observabilité : Sentry + logs structurés | Proposé |
| [0018](./0018-stockage-medias-prives.md) | Médias privés : buckets privés et URL signées | Proposé |
| [0019](./0019-conventions-edge-functions.md) | Conventions des Edge Functions (Deno) | Accepté |
| [0020](./0020-strategie-hors-ligne.md) | Stratégie hors ligne : cache en lecture, file d'envoi | Proposé |
| [0021](./0021-workflow-git.md) | Workflow Git : trunk-based, branches courtes, squash merge | Accepté, amendé par 0025 |
| [0022](./0022-migrations-historiques-rejouables.md) | Rendre rejouables les migrations historiques (amende 0010) | Accepté |
| [0023](./0023-identifiant-et-signature-application.md) | Identifiant `org.aeemg`, nom « AEEMG » et signature release | Accepté |
| [0024](./0024-reconciliation-production.md) | Réconcilier la production avec l'historique des migrations | Accepté |
| [0025](./0025-branches-develop-et-main.md) | Branches `develop` (intégration) et `main` (production) — amende 0021 | Accepté |
