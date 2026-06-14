# AEEMG Connect — Design System

Inspiré de **Muslim Pro** : expérience sombre, spirituelle et moderne.  
Implémentation Flutter : `lib/core/theme/` + `lib/shared/widgets/ds/`

---

## Tokens rapides

| Token | Hex | Usage |
|---|---|---|
| Dark Charcoal | `#262C38` | Fond principal |
| Deep Navy | `#111827` | Footer, surfaces secondaires |
| Card Surface Teal | `#325859` | Cartes, champs |
| Emerald | `#008859` | CTA primaire |
| Bright Green | `#00DB81` | Succès, état actif |
| Soft Mint | `#CCEDDF` | Blocs accent (versets) |
| Gold | `#E8C97A` | Premium, dons |
| White | `#FFFFFF` | Texte principal |
| Warm Gray | `#BEBABC` | Texte secondaire |

## Typographie

- **Rethink Sans** — UI, corps, boutons, labels
- **Manrope** — Titres H1/H2 (≥ 40px)

## Composants Flutter

| Widget | Fichier |
|---|---|
| `AeemgCard` | `shared/widgets/ds/aeemg_card.dart` |
| `AeemgPrimaryButton` | `shared/widgets/ds/aeemg_buttons.dart` |
| `AeemgSecondaryButton` | `shared/widgets/ds/aeemg_buttons.dart` |
| `AeemgAccentCard` | `shared/widgets/ds/aeemg_card.dart` |

## Espacement (base 4px)

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 56`

## Rayons

`4 · 12 · 16 · 20 · 30 (inputs) · 9999 (pill buttons)`

## Ombres cartes

`rgba(0,0,0,0.06) 2px 4px 20px`

---

Voir le cahier complet fourni par l'équipe produit pour les détails responsive, do's/don'ts et états interactifs.
