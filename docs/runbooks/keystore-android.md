# Runbook — Keystore Android (signature release)

Décision : [ADR-0023](../adr/0023-identifiant-et-signature-application.md) · Ticket : SEC-020.

Le keystore d'**upload** signe les AAB envoyés à Google Play. Avec **Play App Signing**, Google
re-signe l'application avec sa propre clé : une clé d'upload perdue ou compromise se **remplace**
auprès de Google (Play Console → Intégrité de l'application → Demander une réinitialisation de la clé
d'importation), mais cela prend plusieurs jours et bloque les mises à jour entre-temps.

**Ne jamais** commiter le keystore, `key.properties` ni les mots de passe ; ne jamais les envoyer par
messagerie ou e-mail en clair.

## 1. Création (une seule fois, par un lead)

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 4096 -validity 10000 -alias upload \
  -dname "CN=AEEMG, O=AEEMG, C=GN"
```

Mots de passe : générés (`openssl rand -base64 32`), différents pour le store et la clé.

## 2. Utilisation locale (build release sur un poste)

Copier `upload-keystore.jks` dans `android/app/` puis créer `android/key.properties` :

```properties
storeFile=upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

`storeFile` est relatif à `android/app/`. Les deux fichiers sont ignorés par git. Sans eux, le build
release échoue volontairement : utiliser `flutter run --profile` ou `--debug` pour les essais.

## 3. Secrets CI (environnement GitHub `production`)

| Secret | Contenu |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEY_PROPERTIES` | le contenu de `key.properties` ci-dessus (avec `storeFile=upload-keystore.jks`) |

`release.yml` reconstitue les fichiers, construit l'AAB et l'APK, puis les supprime.

## 4. Sauvegarde (2 détenteurs au bureau)

- Deux membres du bureau, désignés par écrit (PV de réunion), détiennent chacun une copie :
  keystore + `key.properties` dans un coffre chiffré (gestionnaire de mots de passe d'équipe, ou
  archive chiffrée `age`/`gpg` sur un support hors ligne).
- Les deux copies sont vérifiées **une fois par semestre** : `keytool -list -v -keystore
  upload-keystore.jks` doit afficher l'alias `upload` et la même empreinte SHA-256 que celle de la
  Play Console (Intégrité de l'application → Certificat de la clé d'importation).
- Au départ d'un détenteur : désigner un remplaçant et lui transmettre une copie **avant** son départ ;
  si la copie du partant ne peut pas être récupérée, demander la réinitialisation de la clé d'upload.

## 5. Incident : keystore perdu ou divulgué

1. Supprimer immédiatement les secrets CI concernés.
2. Générer une nouvelle clé d'upload (étape 1) et demander sa réinitialisation dans la Play Console.
3. Mettre à jour les secrets CI et les copies des détenteurs ; consigner l'incident ici (date, cause).
