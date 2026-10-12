# 0007 — La RLS PostgreSQL est la frontière de sécurité

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Tickets liés** : SEC-001 à SEC-018, AMEL-008

## Contexte

Le client Flutter embarque la clé anon publique et appelle directement PostgREST : **tout ce que les policies
autorisent est faisable par n'importe qui**, quelle que soit l'UI. L'audit a trouvé plusieurs failles critiques
dues à des policies trop larges (`using (true)`, `with check (true)`, update sans restriction de colonnes).

## Décision

1. Toute table de `public` a la RLS **activée** et au moins une policy explicite par opération utilisée ; aucune
   policy `using (true)` sur une table contenant des données personnelles ou privées.
2. Les policies UPDATE précisent toujours `using` **et** `with check` ; les colonnes sensibles (rôle, compteurs,
   statut, montants, clés étrangères de rattachement) sont protégées par `GRANT` par colonne ou trigger.
3. Les vérifications de rôle passent **uniquement** par les fonctions helpers (`is_staff()`, `is_admin()`,
   `is_treasurer()`… cf. ADR-0008), jamais par des listes de rôles recopiées dans chaque policy.
4. Toute fonction `SECURITY DEFINER` a `set search_path = ''` et vérifie elle-même les droits de l'appelant.
5. Les buckets Storage contenant des données privées sont privés (ADR-0018).
6. **Chaque policy a ses tests pgTAP** (cas autorisé + cas refusé) dans `supabase/tests/`.
7. L'UI peut masquer des actions (confort), mais n'est jamais considérée comme un contrôle de sécurité.

## Conséquences

- ✅ Sécurité vérifiable automatiquement ; revue facilitée.
- ⚠️ Chaque PR de schéma coûte plus cher (tests) ; les policies complexes peuvent coûter en performance → index (AMEL-016).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Tout passer par des Edge Functions avec service role | Latence, coût, réécriture complète, perte du Realtime |
| Faire confiance à l'UI | Contournable trivialement avec la clé anon |

## Vérification

- Job CI `supabase / db-tests` (pgTAP), dont le test garde-fou `000_rls_enabled.test.sql` (RLS active partout).
- `supabase db lint` en CI.
- Revue obligatoire par un CODEOWNER backend pour `supabase/**`.
