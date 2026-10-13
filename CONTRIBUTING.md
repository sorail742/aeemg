# Contribuer à AEEMG Connect

Merci de contribuer ! Ce guide résume l'essentiel ; les règles complètes sont dans
[docs/team/REGLES_EQUIPE.md](docs/team/REGLES_EQUIPE.md).

## Prérequis

| Outil | Version | Usage |
|---|---|---|
| Flutter | version de la CI (stable, figée par OPS-014) | Application |
| Supabase CLI | ≥ 2.x | Base locale, migrations, tests pgTAP |
| Docker | récent | Supabase local |
| Deno | 2.x | Edge Functions |

## Démarrage rapide

```bash
cp config/example.json config/dev.json   # puis renseigner l'URL et la clé anon du projet de dev
flutter pub get
supabase start                           # base locale (migrations appliquées)
flutter run -d chrome --dart-define-from-file=config/dev.json   # ou un émulateur Android
```

## Cycle de contribution

1. Prendre un ticket `ready` dans le backlog ([docs/tickets/](docs/tickets/README.md)) et se l'assigner.
2. Créer une branche : `git switch -c feat/FEAT-002-transactions`.
3. Développer **avec tests** ; vérifier localement :
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   supabase test db                       # si supabase/ a changé
   deno task check                        # si supabase/functions/ a changé (cf. supabase/functions/deno.json)
   ```
4. Ouvrir une PR (titre Conventional Commit, modèle rempli), en Draft tant que ce n'est pas prêt.
5. Obtenir 2 approbations (dont 1 CODEOWNER) + CI verte, puis **squash merge**.

## Conventions

- Titre de PR / commit : `type(portée): description (ID-TICKET)` — types : `feat`, `fix`, `sec`, `perf`, `refactor`, `test`, `docs`, `ci`, `build`, `chore`, `revert`.
- Nouvelle migration : `supabase migration new description_courte` — jamais modifier une migration mergée.
- Décision structurante : rédiger un ADR (`docs/adr/0000-template.md`).
- Faille de sécurité : **ne pas ouvrir d'issue publique**, voir [SECURITY.md](SECURITY.md).
