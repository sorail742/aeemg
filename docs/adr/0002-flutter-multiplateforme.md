# 0002 — Flutter pour Android, iOS et Web (desktop exclu)

- **Statut** : Accepté
- **Date** : 2026-10-12 (formalisation d'un choix d'avril 2026)
- **Tickets liés** : DEL-006, AMEL-011, OPS-011

## Contexte

Le cahier des charges (§4.1) impose une application mobile (75 % des membres ont un smartphone, Android
majoritaire) **et** un accès web (68,75 % prêts à utiliser un site). L'équipe est bénévole/étudiante,
avec un budget nul : maintenir plusieurs bases de code est impossible. Le dépôt contient aussi les
dossiers `linux/`, `windows/`, `macos/` générés par défaut, jamais testés.

## Décision

- Nous utilisons **Flutter (canal stable, version figée — OPS-014)** pour un code unique.
- Plateformes **supportées** : Android (cible prioritaire), Web (PWA), iOS.
- Plateformes desktop **non supportées** : dossiers supprimés (DEL-006).
- Toute fonctionnalité doit fonctionner sur Android **et** Web, ou être masquée proprement sur la plateforme
  qui ne la supporte pas (`kIsWeb`, imports conditionnels). `dart:io` est interdit hors fichiers `*_io.dart`.
- Versions minimales : celles imposées par la version de Flutter retenue (Android API 24+, iOS 13+), écart
  assumé par rapport au CDC (Android 6 / iOS 12) — à valider par le PO (OPS-011).

## Conséquences

- ✅ Un seul code, une seule équipe, CI unique.
- ⚠️ Taille du bundle Web (CanvasKit/Wasm) pénalisante en 3G → budget de taille en CI (AMEL-010).
- ⚠️ Certains plugins (enregistrement audio, notifications programmées) ont un support Web partiel.

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Natif Kotlin + Swift + site React | 3 bases de code, compétences multiples |
| React Native + site | Pas de Web de qualité équivalente sans duplication ; l'équipe connaît déjà Flutter |
| PWA seule | Notifications push iOS limitées, pas de présence sur les stores |

## Vérification

Job CI `compatibility` : build Android, Web et iOS (sans signature) ; contrôle `policy-checks` refusant `dart:io` hors fichiers dédiés (activé avec AMEL-011).
