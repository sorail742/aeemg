# 0023 — Identifiant d'application `org.aeemg`, nom « AEEMG » et signature release

- **Statut** : Accepté
- **Date** : 2026-10-13
- **Décideurs** : Bureau de l'AEEMG (choix de l'identifiant et du nom), mainteneur du dépôt
- **Tickets liés** : SEC-020, OPS-003, OPS-006

## Contexte

L'application était publiée sous l'identifiant de gabarit Flutter `com.example.aeemg` (refusé par
Google Play) et son build release était signé avec la **clé de debug** : n'importe qui pouvait
produire un APK de « mise à jour » accepté par les appareils. Le produit était appelé « AEEMG Connect »
dans la documentation alors que l'application s'affiche « AEEMG ».

## Décision

1. **Identifiant définitif : `org.aeemg`** (domaine `aeemg.org` inversé), pour toutes les plateformes :
   Android `applicationId` et `namespace`, iOS/macOS `PRODUCT_BUNDLE_IDENTIFIER` (tests :
   `org.aeemg.RunnerTests`), Linux `APPLICATION_ID`. **Il ne change plus jamais** une fois publié :
   un nouvel identifiant est une nouvelle application pour les stores.
2. **Nom du produit : « AEEMG »** (le suffixe « Connect » est abandonné partout). Les migrations
   historiques ne sont pas réécrites (ADR-0010) : une migration de données renomme les contenus en base.
3. **Signature release** : keystore d'upload Google Play **hors dépôt**, décrit par
   `android/key.properties` (ignoré par git, comme `*.jks` / `*.keystore`). En CI, `release.yml` le
   recrée depuis les secrets `ANDROID_KEYSTORE_BASE64` et `ANDROID_KEY_PROPERTIES` de l'environnement
   `production`. **Aucun repli sur la clé de debug** : sans `key.properties`, tout build release échoue
   (tâche Gradle `preReleaseBuild`).
4. **Play App Signing** activé : Google conserve la clé de signature de l'application ; le keystore du
   dépôt n'est que la clé d'**upload**, révocable auprès de Google en cas de perte ou de fuite.

## Conséquences

- ✅ Publication possible sur Google Play ; APK release non falsifiable sans le keystore.
- ✅ `policy-checks` (règle `android-release`) passe : plus de `com.example` ni de signature debug.
- ⚠️ `flutter run --release` / `flutter build apk --release` en local exigent `android/key.properties`
  (utiliser `--profile` ou `--debug` sinon).
- ⚠️ Les installations de test faites sous `com.example.aeemg` sont une autre application : les
  désinstaller.
- ⚠️ Le keystore est un secret critique : procédure de sauvegarde (2 détenteurs au bureau) dans
  [docs/runbooks/keystore-android.md](../runbooks/keystore-android.md).

## Vérification

`policy-checks` (règle `android-release`, bloquante dans `release.yml`) ; job `release / android` :
échec explicite sans secrets, AAB signé avec.
