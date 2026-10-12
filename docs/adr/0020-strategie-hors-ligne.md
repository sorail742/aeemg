# 0020 — Stratégie hors ligne : cache en lecture, file d'envoi

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : REL-015, AMEL-019, AMEL-025, FEAT-034

## Contexte

Connectivité irrégulière et data coûteuse (CDC §4.3, §8). Un cache JSON dans `SharedPreferences` existe pour
l'accueil et l'agenda ; le Coran est déjà embarqué.

## Décision

- **Lecture** : stale-while-revalidate pour l'accueil, l'agenda, les annonces, le contenu islamique, les 50 derniers
  messages par groupe ; date de dernière mise à jour affichée.
- **Écriture** : file locale persistée pour messages texte, RSVP, retours (UUID générés côté client = idempotence).
  Paiements et opérations d'administration : **jamais** hors ligne.
- Stockage : SharedPreferences pour de petites valeurs ; base locale (Drift/SQLite, décision à confirmer à l'implémentation de REL-015) au-delà.
- Données sensibles (messages privés) chiffrées au repos ou non mises en cache.

## Conséquences

- ✅ App utilisable en zone mal couverte ; moins de data consommée.
- ⚠️ Gestion des conflits (RSVP modifié ailleurs) : dernière écriture gagne, documenté.

## Vérification

Tests unitaires de la file ; test d'intégration en mode avion.
