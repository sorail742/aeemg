#!/usr/bin/env bash
# Budget de taille du build web (AMEL-010 : chargement < 3 s en 3G).
# Usage : tool/ci/check_size_budget.sh <budget-ko-gzip>   (0 = rapport seulement)
set -euo pipefail
budget_kb="${1:-0}"
js="build/web/main.dart.js"
[[ -f "$js" ]] || { echo "::error::$js introuvable"; exit 1; }

raw_kb=$(( $(wc -c < "$js") / 1024 ))
gz_kb=$(( $(gzip -9 -c "$js" | wc -c) / 1024 ))
total_kb=$(du -sk build/web | cut -f1)

echo "main.dart.js : ${raw_kb} Ko (gzip ${gz_kb} Ko) — build/web total : ${total_kb} Ko"
{
  echo "### Taille du build web"
  echo "| Fichier | Brut | Gzip | Budget gzip |"
  echo "|---|---|---|---|"
  echo "| main.dart.js | ${raw_kb} Ko | ${gz_kb} Ko | ${budget_kb} Ko |"
  echo "| build/web (total) | ${total_kb} Ko | | |"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

if (( budget_kb > 0 && gz_kb > budget_kb )); then
  echo "::error::main.dart.js gzip ${gz_kb} Ko > budget ${budget_kb} Ko (AMEL-010)."
  exit 1
fi
