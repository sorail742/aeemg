# 0009 — Configuration par `--dart-define-from-file`

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : SEC-019, DEL-009, REL-010, AMEL-013

## Contexte

La configuration est lue depuis `.env` via `flutter_dotenv`, et `.env` est déclaré comme **asset** : il est
copié dans l'APK et publié sur le Web (`assets/.env`). Le build échoue si le fichier est absent, et rien
n'empêche d'y placer un secret.

## Décision

- La configuration client est injectée à la compilation : `flutter run --dart-define-from-file=config/dev.json`.
- `config/dev.json` et `config/staging.json` sont versionnés (ils ne contiennent **que** des valeurs publiques :
  URL Supabase, clé anon/publishable, DSN Sentry, nom d'environnement). `config/prod.json` est généré par la CI.
- Lecture via `const String.fromEnvironment('SUPABASE_URL')` dans `lib/core/config/env.dart`.
- **Aucun secret** n'est jamais présent dans le client : clés service role, API SMS/paiement → secrets d'Edge Functions.

## Conséquences

- ✅ Plus de fichier publié par erreur ; valeurs constantes (tree-shaking) ; environnements explicites.
- ⚠️ Changer de configuration impose un rebuild (acceptable).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Garder `flutter_dotenv` sans asset | Impossible : le paquet lit un asset |
| Flavors natifs seuls | Ne couvre pas le Web |

## Vérification

`policy-checks` : échec si `.env` est listé dans les assets de `pubspec.yaml` ou si un motif de secret (`service_role`, `sk_live`, clé privée) apparaît dans `lib/`, `web/`, `assets/` ou `config/`.
