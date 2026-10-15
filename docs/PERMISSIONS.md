# Permissions de l'application (SEC-025)

Chaque permission déclarée est justifiée ici. Toute nouvelle permission passe par une PR qui met
à jour ce document (fonctionnalité, écran, moment de la demande, texte affiché).

Principes :
- **demande au moment de l'usage**, jamais au lancement de l'app ;
- **refus géré** : la fonctionnalité concernée est simplement indisponible, avec une explication
  et un moyen de réessayer (ou d'ouvrir les réglages si le refus est définitif) ;
- **minimum nécessaire** : position approximative plutôt que précise, galerie plutôt que caméra.

## Android (`android/app/src/main/AndroidManifest.xml`)

| Permission | Fonctionnalité | Écran | Moment de la demande | Si refusée |
|---|---|---|---|---|
| `INTERNET` | Toute l'app (Supabase) | — | Pas de demande (permission normale) | — |
| `ACCESS_COARSE_LOCATION` | Heures de prière de la ville | Accueil, carte « Heures de prière » | Bouton « Activer la localisation » | Carte explicative ; réessayer ; réglages si refus définitif |
| `RECORD_AUDIO` | Messages vocaux ; test de récitation | Discussion ; Coran → Test de récitation | Premier appui sur le micro | Pas d'enregistrement, le reste fonctionne |
| `POST_NOTIFICATIONS` (Android 13+) | Rappels d'adhan | Accueil, cloche sous chaque prière | Premier appui sur une cloche | Pas de rappel |
| `SCHEDULE_EXACT_ALARM` | Adhan à l'heure exacte | Idem | Premier appui sur une cloche (écran système « Alarmes et rappels ») | Rappel approximatif (quelques minutes de décalage possibles) |
| `RECEIVE_BOOT_COMPLETED` | Reprogrammer les rappels après redémarrage | — | Pas de demande (permission normale) | — |
| `VIBRATE` | Vibration des rappels | — | Pas de demande (permission normale) | — |

Retirées par SEC-025 :
- `ACCESS_FINE_LOCATION` : la position approximative suffit à calculer des heures de prière ;
- `CAMERA` : l'app n'utilise que la galerie (`ImageSource.gallery`) ;
- `USE_EXACT_ALARM` : Google Play la réserve aux applications de réveil et d'agenda.

Le paquet `permission_handler`, déclaré mais jamais utilisé, a aussi été retiré.

## iOS (`ios/Runner/Info.plist`)

| Clé | Fonctionnalité | Texte affiché |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | Heures de prière | « Votre position approximative sert uniquement à calculer les heures de prière de votre ville. Elle n'est ni enregistrée ni partagée. » |
| `NSMicrophoneUsageDescription` | Messages vocaux, test de récitation | Inchangé |
| `NSSpeechRecognitionUsageDescription` | Correction de la récitation | Inchangé |
| `NSPhotoLibraryUsageDescription` | Envoi d'images (discussions, publications) | Inchangé |
| `UIBackgroundModes` : `audio` | Écoute du Coran écran verrouillé | — |

Retirées par SEC-025 : `NSLocationAlwaysUsageDescription` (seul « pendant l'utilisation » est
nécessaire), `NSCameraUsageDescription` (pas de caméra) et le mode d'arrière-plan `fetch` (inutilisé).

## Formulaire « Sécurité des données » (Google Play) et étiquettes de confidentialité (App Store)

| Donnée | Collectée | Partagée | Finalité | Commentaire |
|---|---|---|---|---|
| Position approximative | Non | Non | Fonctionnalité de l'app | Calcul local des heures de prière ; seule la ville est affichée. Le géocodage inverse interroge le service système (Google, Apple) |
| Adresse e-mail | Oui | Non | Gestion du compte | Supabase Auth |
| Nom, téléphone, section, spécialité | Oui | Non | Fonctionnalité (annuaire des membres) | Visibilité réglable par le membre |
| Messages, images, messages vocaux | Oui | Non | Fonctionnalité (messagerie) | Stockage privé, accès réservé aux membres du groupe (SEC-006) |
| Enregistrements audio du test de récitation | Non | Non | Fonctionnalité | Reconnaissance vocale du système, rien n'est stocké par l'app |
| Dons (montant, moyen de paiement) | Oui | Oui (prestataire de paiement) | Paiement | Orange Money (FEAT-004) |

Chiffrement en transit : oui (HTTPS). Suppression du compte : par un administrateur (SEC-023) ; par le
membre lui-même : FEAT-038 (exigée par Google Play pour les apps avec création de compte).
