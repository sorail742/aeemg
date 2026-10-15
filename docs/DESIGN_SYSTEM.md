# Système de design AEEMG

Inspiré de **Muslim Pro** : expérience sombre, spirituelle et moderne. Thème sobre, une seule couleur
d'action. Les écrans utilisent les **tokens** et les **composants** ci-dessous, jamais de valeurs en dur
(AMEL-022). Implémentation : `lib/core/theme/` et `lib/shared/widgets/ds/`.

> **Version 3 (octobre 2026, AMEL-027)** : mouvement, profondeur et identité. Même palette et mêmes règles
> que la v2, plus des dégradés, un halo, un motif étoilé, une navigation flottante et des animations
> courtes (section « v3 » ci-dessous). Tout reste léger : aucune image, aucun flou, aucune nouvelle
> dépendance.
>
> Version 2 (octobre 2026) : remplace les valeurs de la première version, qui ne correspondaient plus
> au code (polices Rethink Sans/Manrope, carte `#325859`, rayons de 30 px). Le cahier complet de
> l'équipe produit reste la référence pour le responsive et les états interactifs détaillés.

## Principes

1. **Une couleur d'action** : émeraude pour les boutons, liens, éléments actifs. L'**or** est réservé
   aux contenus islamiques (versets, hadiths, rappels) et aux mises en avant (annonce importante,
   administration).
2. **Profondeur par les surfaces**, pas par les ombres : fond → carte (`cardSurface`) → surface
   surélevée (`cardSurfaceLight`), séparés par une bordure fine (`border`).
3. **Hiérarchie typographique courte** : un titre de page, des titres de section, du texte. Pas
   d'emoji dans l'interface, pas de couleur sur les titres.
4. **États vides et erreurs explicites** : icône, titre, explication, action éventuelle
   (`AeemgEmptyState`). Jamais un texte gris seul ni une erreur brute.
5. **Français partout** : `MaterialApp` est en `fr` (sélecteurs de date, libellés système) ; les
   calendriers commencent le lundi.
6. **Animations courtes et utiles** (v3) : apparition en cascade des blocs d'un écran (≤ 400 ms,
   8 éléments au plus), retour tactile, transitions de page. Toutes sont coupées quand le système
   demande de réduire les animations.

## Tokens (`lib/core/theme/`)

| Fichier | Contenu |
|---|---|
| `app_colors.dart` | Fonds (`deepNavy`, `darkCharcoal`, `darkTeal`), surfaces (`cardSurface`, `cardSurfaceLight`, `border`), action (`emerald`, `brightGreen`, `onPrimary`), accent (`gold`), textes (`white`, `textSecondary`, `textTertiary`), sémantique (`error`, `success`, `warning`, `info`), utilitaires (`transparent`, `scrim` pour les voiles et ombres, `avatarPalette` pour les noms d'expéditeurs) |
| `app_typography.dart` | `display` 32, `h1` 26, `h2` 20, `h3` 17, `h4` 15, `body` 15, `bodyLarge` 16, `bodySmall` 13, `caption` 12, `overline` 11 (capitales espacées) ; Outfit pour les titres, Inter pour le texte, Amiri pour l'arabe |
| `app_spacing.dart` | Grille de 4 px : `xs` 4, `sm` 8, `smMd` 12, `md` 16, `lg` 24, `xl` 32, `xxl` 40 |
| `app_radius.dart` | `input` 12 (champs, boutons), `card` 16 (cartes), `pill` |
| `app_shadows.dart` | Pas d'ombre sur les cartes ; `elevated` pour les éléments flottants |
| `app_theme.dart` | Thème Material 3 : barres, champs, boutons (52 px de haut), onglets, dialogues, feuilles, menus, interrupteurs |

Contrastes (WCAG AA) : texte principal 15:1, secondaire 7:1, texte tertiaire réservé aux libellés
secondaires ; texte sur émeraude en `onPrimary` (sombre, 8:1) et non en blanc.

## Composants (`lib/shared/widgets/ds/`)

| Composant | Usage |
|---|---|
| `IslamicBackground` | Fond de chaque écran : dégradé, halo émeraude en haut (v3), motif étoilé à 2 % avec `withPattern` |
| `AeemgCard` | Carte standard (reflet en haut, v3) ; variantes `accent` (teinte émeraude) et `active` (bordure émeraude) ; s'enfonce sous le doigt si `onTap` |
| `AeemgAccentCard` | Verset, hadith, rappel : filet doré, titre en capitales, texte en italique |
| `AeemgPrimaryButton` / `AeemgSecondaryButton` | Action principale (dégradé émeraude et halo, v3) / secondaire, pleine largeur par défaut |
| `AeemgSectionHeader` | Titre de section, action « Tout voir » facultative |
| `AeemgEmptyState` | État vide ou d'erreur (`compact: true` dans une liste) |
| `AeemgSuccessBadge` | Pastille de statut |

## v3 : mouvement et profondeur

| Élément | Où | Règle |
|---|---|---|
| `AppMotion` | `app_motion.dart` | Durées `fast` 150 ms, `base` 250 ms, `slow` 400 ms ; décalage 45 ms ; `AppMotion.reduced(context)` |
| `AppGradients` | `app_gradients.dart` | `primary` (bouton principal), `hero` (bandeau), `gold`, `surface` (reflet des cartes), `glow` (halo du fond) |
| Transitions de page | `app_theme.dart` | Fondu enchaîné (Android, Web, desktop), geste natif (iOS, macOS) |
| `AppShadows.glow` / `floating` | `app_shadows.dart` | Halo du bouton principal ; ombre de la barre flottante |
| `AppColors.violet` | `app_colors.dart` | Teinte d'accent secondaire (raccourcis, catégories) |

| Composant v3 | Usage |
|---|---|
| `AeemgNavBar` | Barre de navigation flottante (îlot arrondi, pastille émeraude animée sous l'onglet actif) |
| `AeemgHero` | Bandeau en tête d'écran de section : dégradé émeraude, motif étoilé, halo doré |
| `AeemgPressable` | Retour tactile (l'élément s'enfonce à 97 %) ; déjà intégré aux cartes cliquables et au bouton principal |
| `.reveal(context, index: i)` | Apparition en cascade d'un bloc (fondu + glissement de 6 %) |
| `AeemgSkeleton`, `AeemgSkeletonTile` | Chargement à la forme du contenu attendu, à la place d'un indicateur circulaire |
| `AeemgPillTabBar` | Onglets en pilule (onglet actif en dégradé), à la place d'une TabBar soulignée |
| `AeemgRoundIconButton` | Bouton d'icône rond (surface de carte, bordure fine, badge facultatif) pour les en-têtes sans AppBar |
| `IslamicPatternPainter` | Motif d'étoiles à huit branches (fond à 2 %, bandeau à 6 %) |

Règles v3 :
- Un écran de section commence par un `AeemgHero` ou par un titre de page, jamais les deux.
- Chargement d'une liste : `AeemgSkeletonTile`, jamais un `CircularProgressIndicator` seul au milieu de l'écran.
- Les blocs principaux d'un écran apparaissent avec `.reveal` dans l'ordre de lecture ; pas dans les listes
  longues paginées.
- Pas de `BackdropFilter` (flou) : trop coûteux sur les téléphones d'entrée de gamme.

## Contrôle automatique

`tool/ci/check_repo_policies.sh`, règle bloquante **`design-tokens`** (job `policy-checks`) : aucune
couleur Material (`Colors.white70`, `Colors.red`…) hors de `lib/core/theme/`. Correspondance à
utiliser :

| Au lieu de | Token |
|---|---|
| `Colors.white` | `AppColors.white` |
| `Colors.white70`, `white60`, `white54` | `AppColors.textSecondary` |
| `Colors.white38`, `white30`, `Colors.grey` | `AppColors.textTertiary` |
| `Colors.white24`, `white12` | `AppColors.border` |
| `Colors.red`, `redAccent` | `AppColors.error` |
| `Colors.orange` | `AppColors.warning` |
| `Colors.blue`, `lightBlue` | `AppColors.info` |
| `Colors.black` (voile, ombre) | `AppColors.scrim.withValues(alpha: …)` |
| `Colors.transparent` | `AppColors.transparent` |

## Règles pour un nouvel écran

- `AppBar` sans style local : le thème fixe couleurs, titre et bordure.
- Contenu dans un `ListView` avec `EdgeInsets.fromLTRB(md, lg, md, xxl)`.
- Listes de réglages : une carte, lignes séparées par `Divider(indent: 56)` (voir `profile_screen.dart`).
- Champs : `InputDecoration(labelText: …, prefixIcon: …)` sans bordure ni couleur locale.
- Avant de fusionner : capture d'écran avant/après dans la PR.
