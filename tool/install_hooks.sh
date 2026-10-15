#!/usr/bin/env bash
# Active les hooks Git versionnés dans tool/hooks/ (OPS-012) pour ce clone.
# Désactivation : git config --unset core.hooksPath
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x tool/hooks/*
git config core.hooksPath tool/hooks
echo "Hooks activés (core.hooksPath = tool/hooks) :" tool/hooks/*
