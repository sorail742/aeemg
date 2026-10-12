# 0018 — Médias privés : buckets privés et URL signées

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : SEC-006, SEC-007, REL-009, FEAT-012

## Contexte

Les images et messages vocaux des conversations sont dans des buckets **publics** ; l'URL publique est stockée
en base. Toute personne qui obtient l'URL accède au média, même sans compte.

## Décision

| Bucket | Visibilité | Chemin | Lecture | Écriture | Limites |
|---|---|---|---|---|---|
| `chat_images` | privé | `<group_id>/<uuid>.<ext>` | membres du groupe | membres du groupe | 5 Mo, jpeg/png/webp |
| `chat_audio` | privé | `<group_id>/<uuid>.<ext>` | membres du groupe | membres du groupe | 10 Mo, m4a/ogg/webm |
| `chat_documents` | privé | `<group_id>/<uuid>.pdf` | membres du groupe | membres du groupe | 10 Mo, pdf |
| `social_images` | public | `<user_id>/<uuid>.<ext>` | tous | propriétaire | 5 Mo, images |
| `avatars` | public | `<user_id>/avatar.<ext>` | tous | propriétaire | 2 Mo, images |

- La base stocke le **chemin**, jamais l'URL. Le client crée des URL signées (durée 1 h) et les met en cache.
- Les policies Storage utilisent `storage.foldername(name)` pour vérifier l'appartenance.

## Conséquences

- ✅ Confidentialité des conversations.
- ⚠️ Une requête de signature supplémentaire par média (atténuée par `createSignedUrls` en lot et le cache).

## Vérification

Tests pgTAP sur `storage.objects` ; test qu'une URL publique d'un bucket privé renvoie une erreur.
