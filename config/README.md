# Configuration de l'application (ADR-0009)

La configuration est injectée **à la compilation**, jamais embarquée comme fichier :

```bash
cp config/example.json config/dev.json   # puis renseigner l'URL et la clé anon du projet
flutter run --dart-define-from-file=config/dev.json
```

| Fichier | Versionné | Usage |
|---|---|---|
| `example.json` | oui | Modèle (valeurs factices) ; utilisé par la CI pour compiler |
| `dev.json`, `staging.json` | non | Postes de développement / recette |
| `prod.json` | non | Généré par `release.yml` depuis le secret `APP_CONFIG_JSON` |

Clés : `APP_ENV` (`dev` / `staging` / `prod`), `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

**Valeurs publiques uniquement** : l'URL et la clé anon/publishable finissent dans le binaire et
le JavaScript web. Jamais de clé « service role », de clé API SMS ou de paiement : elles vont dans
les secrets des Edge Functions (`policy-checks` refuse ces motifs dans `config/`).
