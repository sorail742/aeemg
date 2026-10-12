# 0010 — Migrations SQL versionnées via Supabase CLI

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Tickets liés** : REL-001 à REL-004, DEL-001, DEL-012, OPS-005

## Contexte

Le schéma a été appliqué en copiant-collant du SQL dans le Dashboard (`APPLY_ALL.sql`, docs « exécuter X dans
Supabase »). Résultat : deux migrations de même version, une migration non exécutable, une copie divergente.

## Décision

1. `supabase/migrations/` est l'**unique** source de vérité du schéma.
2. Nom : `AAAAMMJJHHMMSS_description_snake_case.sql`, généré par `supabase migration new <nom>`. Version unique (contrôle CI).
3. Une migration mergée n'est **jamais modifiée** ; on corrige par une nouvelle migration. Seule exception :
   le **renommage pur** (contenu identique) pour corriger une version dupliquée, accompagné de la procédure
   `supabase migration repair` (cas de REL-001).
4. Migrations idempotentes autant que possible (`if not exists`, `drop policy if exists`, `on conflict do nothing`).
5. Pas de données de démo dans les migrations : `supabase/seed.sql` (local/CI uniquement).
6. Changements destructifs (drop colonne/table, rename) en **deux releases** : dépréciation, puis suppression
   après que les versions mobiles anciennes ne sont plus supportées.
7. Application aux environnements **uniquement par la CI** (`supabase db push`) — jamais à la main en prod.

## Conséquences

- ✅ Environnements reproductibles ; `supabase db reset` en CI détecte les migrations cassées.
- ⚠️ Les bases existantes appliquées à la main doivent être alignées (`supabase migration repair`) une fois.

## Vérification

Job CI `supabase` : unicité des versions, format des noms, `db reset` sur base vierge, `db lint`, tests pgTAP ;
interdiction de modifier un fichier de migration déjà présent sur `main` (contrôle par diff).
