# 0013 — Internationalisation avec `gen-l10n` (FR, Peul, Arabe)

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : AMEL-005, FEAT-028

## Contexte

Le CDC impose le français, puis le peul et l'arabe. L'implémentation actuelle (`AppStrings`, map statique)
ne couvre que la navigation, sans pluriels ni paramètres ; la majorité des textes est en dur.

## Décision

- Outil officiel Flutter **`gen-l10n`** avec fichiers ARB : `lib/l10n/app_fr.arb` (modèle), `app_ff.arb`, `app_ar.arb`.
- Langue par défaut : `fr` ; repli `fr` pour toute clé manquante ; préférence stockée dans `profiles.preferred_locale` (contrainte à étendre à `ar`).
- Clés en `snake_case` préfixées par la feature (`events_rsvp_button`).
- Mise en page compatible **RTL** : `EdgeInsetsDirectional`, `AlignmentDirectional`, pas de `left/right` codés en dur.
- Dates et montants via `intl` (`NumberFormat.currency(locale, symbol: 'GNF', decimalDigits: 0)`).
- Le contenu religieux (versets, hadiths) n'est **pas** dans les ARB : il vient de la base / des assets avec validation.

## Conséquences

- ✅ Traductions outillées, pluriels, vérification à la compilation.
- ⚠️ Migration de toutes les chaînes existantes (travail mécanique, découpable par feature).

## Vérification

`flutter gen-l10n` en CI ; contrôle grep des chaînes en dur dans `presentation/` (activé à la fin d'AMEL-005).
