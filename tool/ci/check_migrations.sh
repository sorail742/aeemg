#!/usr/bin/env bash
# Vérifie les migrations Supabase (ADR-0010) :
#  - nom au format AAAAMMJJHHMMSS_description.sql
#  - versions uniques
#  - aucune migration déjà présente sur la branche de base n'a été modifiée/supprimée
# Usage : tool/ci/check_migrations.sh [ref-de-base]   (ex. origin/main)
set -uo pipefail

dir="supabase/migrations"
base="${1:-}"
errors=0

err() { echo "::error file=$1,title=migrations::$2"; errors=$((errors + 1)); }

declare -A seen
for path in "$dir"/*.sql; do
  [[ -e "$path" ]] || continue
  name=$(basename "$path")
  if [[ ! "$name" =~ ^([0-9]{14})_[a-z0-9_]+\.sql$ ]]; then
    err "$path" "Nom invalide « $name » : attendu AAAAMMJJHHMMSS_description_snake_case.sql (supabase migration new)."
    continue
  fi
  version="${BASH_REMATCH[1]}"
  if [[ -n "${seen[$version]:-}" ]]; then
    err "$path" "Version ${version} dupliquée avec ${seen[$version]} : la CLI Supabase n'appliquera qu'une des deux (REL-001)."
  else
    seen[$version]="$name"
  fi
done

if [[ -n "$base" ]] && git rev-parse --verify --quiet "$base" >/dev/null; then
  while IFS=$'\t' read -r status file newfile; do
    [[ -z "$status" ]] && continue
    case "$status" in
      A) ;; # nouvelle migration : OK
      R100)
        # Renommage pur (contenu identique) : seule façon de corriger une version
        # dupliquée (REL-001). Les bases déjà migrées doivent être réparées.
        echo "::warning file=${newfile},title=migrations::Migration renommée sans changement de contenu (${file} -> ${newfile}) : prévoir 'supabase migration repair' sur les bases déjà migrées (docs/SUPABASE_SETUP.md)." ;;
      *) err "${newfile:-$file}" "Migration existante modifiée/supprimée (statut ${status}) : créer une nouvelle migration à la place (ADR-0010)." ;;
    esac
  done < <(git diff --name-status -M100% "$base"...HEAD -- "$dir")
fi

echo "Migrations : ${#seen[@]} version(s), ${errors} erreur(s)."
(( errors == 0 ))
