#!/usr/bin/env bash
# Calcule la couverture de lignes depuis coverage/lcov.info et échoue sous le seuil.
# Usage : tool/ci/check_coverage.sh <seuil-en-pourcentage>
set -euo pipefail
min="${1:-0}"
file="coverage/lcov.info"
[[ -f "$file" ]] || { echo "::error::$file introuvable (flutter test --coverage)"; exit 1; }

read -r hit found < <(awk -F: '/^LH:/{h+=$2} /^LF:/{f+=$2} END{print h+0, f+0}' "$file")
pct=$(awk -v h="$hit" -v f="$found" 'BEGIN{ if (f==0) print "0.00"; else printf "%.2f", 100*h/f }')

echo "Couverture : ${pct}% (${hit}/${found} lignes) — seuil ${min}%"
{
  echo "### Couverture de tests"
  echo "| Lignes couvertes | Total | Couverture | Seuil |"
  echo "|---|---|---|---|"
  echo "| ${hit} | ${found} | **${pct} %** | ${min} % |"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

if awk -v p="$pct" -v m="$min" 'BEGIN{exit !(p+0 < m+0)}'; then
  echo "::error::Couverture ${pct}% inférieure au seuil ${min}% (ADR-0014)."
  exit 1
fi
