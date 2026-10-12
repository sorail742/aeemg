# 0004 — Riverpod pour l'injection et la gestion d'état

- **Statut** : Accepté
- **Date** : 2026-10-12 (formalisation)
- **Tickets liés** : AMEL-002, AMEL-004

## Contexte

`flutter_riverpod` 2.x est déjà utilisé dans 56 fichiers (providers de repositories, `FutureProvider`,
`StreamProvider`). Mais une partie de la logique est encore dans les widgets (`setState`, appels Supabase directs).

## Décision

- **Riverpod** est l'unique mécanisme d'injection de dépendances et de gestion d'état.
- Repositories exposés via `Provider` ; états d'écran via `Notifier`/`AsyncNotifier` (pas de nouveau `StateNotifier`/`ChangeNotifier`).
- Les widgets ne contiennent **aucun** appel réseau : ils lisent des providers et appellent des méthodes de contrôleurs.
- `setState` reste autorisé pour l'état purement visuel local (animation, champ de formulaire).
- Providers liés à un écran : `autoDispose`.
- La migration vers Riverpod 3 / génération de code (`riverpod_generator`) fera l'objet d'un ADR séparé.

## Conséquences

- ✅ Testabilité (overrides), cohérence, pas de fuite d'abonnements Realtime.
- ⚠️ Courbe d'apprentissage pour les nouveaux ; refactor progressif des gros écrans (AMEL-001/002).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| BLoC | Plus verbeux ; migration totale coûteuse sans bénéfice clair |
| Provider | Prédécesseur de Riverpod, moins sûr à la compilation |
| GetX | Couplage fort, mauvaises pratiques de test |

## Vérification

Règle CI (AMEL-002) : pas d'import `supabase_flutter` dans `lib/features/*/presentation/`.
