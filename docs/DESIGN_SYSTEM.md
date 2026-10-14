# Système de design AEEMG

Inspiré de **Muslim Pro** : expérience sombre, spirituelle et moderne. Thème sobre, une seule couleur
d'action. Les écrans utilisent les **tokens** et les **composants** ci-dessous, jamais de valeurs en dur
(AMEL-022). Implémentation : `lib/core/theme/` et `lib/shared/widgets/ds/`.

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
6. **Animations discrètes** : fondu court (≤ 250 ms) à l'ouverture d'un écran ; pas de rebond ni
   d'apparition en cascade.

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
| `IslamicBackground` | Fond de chaque écran (dégradé, motif géométrique à 2 % d'opacité avec `withPattern`) |
| `AeemgCard` | Carte standard ; variantes `accent` (teinte émeraude) et `active` (bordure émeraude) |
| `AeemgAccentCard` | Verset, hadith, rappel : filet doré, titre en capitales, texte en italique |
| `AeemgPrimaryButton` / `AeemgSecondaryButton` | Action principale / secondaire, pleine largeur par défaut |
| `AeemgSectionHeader` | Titre de section, action « Tout voir » facultative |
| `AeemgEmptyState` | État vide ou d'erreur (`compact: true` dans une liste) |
| `AeemgSuccessBadge` | Pastille de statut |

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
