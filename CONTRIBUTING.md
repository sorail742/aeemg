# Contribuer à AEEMG

Merci de contribuer ! Ce guide résume l'essentiel ; les règles complètes sont dans
[docs/team/REGLES_EQUIPE.md](docs/team/REGLES_EQUIPE.md).

## Prérequis

| Outil | Version | Usage |
|---|---|---|
| Flutter | **exactement** celle de [`.fvmrc`](.fvmrc) (OPS-014) — `fvm use` avec [FVM](https://fvm.app), sinon vérifier `flutter --version` | Application |
| Supabase CLI | ≥ 2.x | Base locale, migrations, tests pgTAP |
| Docker | récent | Supabase local |
| Deno | 2.x | Edge Functions |

## Démarrage rapide

```bash
cp config/example.json config/dev.json   # puis renseigner l'URL et la clé anon du projet de dev
flutter pub get
tool/install_hooks.sh                    # hooks Git : format, analyse, politiques, message de commit
supabase start                           # base locale (migrations appliquées)
flutter run -d chrome --dart-define-from-file=config/dev.json   # ou un émulateur Android
```

## Cycle de contribution

1. Prendre un ticket `ready` dans le backlog ([docs/tickets/](docs/tickets/README.md)) et se l'assigner.
2. Créer une branche depuis `develop` : `git switch -c feat/FEAT-002-transactions origin/develop`.
3. Développer **avec tests** ; vérifier localement :
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   supabase test db                       # si supabase/ a changé
   deno task check                        # si supabase/functions/ a changé (cf. supabase/functions/deno.json)
   ```
4. Ouvrir une PR **vers `develop`** (titre Conventional Commit, modèle rempli), en Draft tant que ce n'est pas prêt.
5. Obtenir 2 approbations (dont 1 CODEOWNER) + CI verte, puis **squash merge**.

Mise en production (Tech Lead, [ADR-0025](docs/adr/0025-branches-develop-et-main.md)) : PR `develop` → `main`
titrée `chore(release): vX.Y.Z`, fusionnée en **merge commit** (jamais en squash), puis tag `vX.Y.Z` sur `main`.
Correctif urgent : `hotfix/<ID>-…` depuis `main`, PR vers `main`, puis fusion de `main` dans `develop`.

## Version de Flutter (OPS-014)

- La version est figée dans [`.fvmrc`](.fvmrc) ; la CI et les releases la lisent (`flutter-version-file`).
  Seul le job informatif `android (beta)` utilise la dernière beta, pour anticiper la montée suivante.
- Avec une autre version en local, `flutter pub get` réécrit la section `sdks` de `pubspec.lock` :
  ne pas committer ce changement.
- **Monter de version** = une PR dédiée (`build(flutter): Flutter X.Y.Z (OPS-014)`) qui ne change que `.fvmrc`
  (et `pubspec.lock` si nécessaire), et qui passe toute la matrice `compatibility`.

## Hooks Git (OPS-012)

`tool/install_hooks.sh` active les hooks versionnés dans `tool/hooks/` (`git config core.hooksPath tool/hooks`) :

| Hook | Contrôle | Équivalent CI |
|---|---|---|
| `pre-commit` | `dart format` et `dart analyze --fatal-infos` sur les fichiers Dart indexés ; règles bloquantes de `tool/ci/check_repo_policies.sh` | `flutter / format`, `analyze`, `policy-checks` |
| `commit-msg` | Conventional Commits, mêmes types que le titre de PR | `pr-quality / title` |

- Environ une seconde par commit : seuls les fichiers indexés sont analysés.
- Contournement exceptionnel : `git commit --no-verify`. La CI refera les mêmes contrôles.
- Désactivation : `git config --unset core.hooksPath`.

## Conventions

- Titre de PR / commit : `type(portée): description (ID-TICKET)` — types : `feat`, `fix`, `sec`, `perf`, `refactor`, `test`, `docs`, `ci`, `build`, `chore`, `revert`.
- Nouvelle migration : `supabase migration new description_courte` — jamais modifier une migration mergée.
- Décision structurante : rédiger un ADR (`docs/adr/0000-template.md`).
- Faille de sécurité : **ne pas ouvrir d'issue publique**, voir [SECURITY.md](SECURITY.md).
