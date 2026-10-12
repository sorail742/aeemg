#!/usr/bin/env bash
# Contrôles de politique du dépôt (sécurité, maintenabilité, conventions).
# Les règles « error » font échouer la CI ; les règles « warn » produisent des
# annotations GitHub et deviennent « error » quand le ticket associé est livré
# (passer la règle dans ERROR_RULES ci-dessous).
#
# Usage : tool/ci/check_repo_policies.sh  (depuis la racine du dépôt)
set -uo pipefail

# Règles promues en erreur bloquante. Ajouter l'ID quand le ticket est livré.
ERROR_RULES="${ERROR_RULES:-secrets forbidden-files service-role}"
# Ex. après SEC-019 : ERROR_RULES="... env-asset" ; après AMEL-001 : "... file-size"

errors=0
warnings=0

is_error() { [[ " $ERROR_RULES " == *" $1 "* ]]; }

report() { # rule file line message
  local rule="$1" file="$2" line="$3" msg="$4"
  local loc="file=${file}"
  [[ -n "$line" ]] && loc="${loc},line=${line}"
  if is_error "$rule"; then
    echo "::error ${loc},title=${rule}::${msg}"
    errors=$((errors + 1))
  else
    echo "::warning ${loc},title=${rule}::${msg}"
    warnings=$((warnings + 1))
  fi
}

tracked() { git ls-files -- "$@" 2>/dev/null; }

# 1. Fichiers interdits dans le dépôt (secrets, keystores, configs locales)
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    .env.example|*/.env.example) continue ;;
  esac
  report forbidden-files "$f" "" "Fichier sensible versionné : à retirer du dépôt et à faire tourner (rotation) si c'est un secret."
done < <(tracked '.env' '*/.env' '*.jks' '*.keystore' '*.p12' '*.p8' '*.mobileprovision' \
  'android/key.properties' '**/service-account*.json' 'supabase/.env' 'supabase/functions/.env')

# 2. Motifs de secrets dans le code client et la configuration publique
secret_regex='(service_role|SERVICE_ROLE_KEY[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']+|sk_live_[0-9a-zA-Z]+|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16})'
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report secrets "$f" "$l" "Motif de secret détecté dans du code embarqué côté client (ADR-0009)."
done < <(git grep -nIE "$secret_regex" -- lib web assets config 2>/dev/null || true)

# 3. JWT service_role en dur n'importe où (payload base64 contenant "role":"service_role")
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report service-role "$f" "$l" "Jeton JWT service_role versionné : rotation immédiate requise."
done < <(git grep -nIE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]*c2VydmljZV9yb2xl' -- . 2>/dev/null || true)

# 4. .env embarqué dans les assets Flutter (SEC-019)
if grep -nE '^[[:space:]]*-[[:space:]]*\.env[[:space:]]*$' pubspec.yaml >/dev/null; then
  l=$(grep -nE '^[[:space:]]*-[[:space:]]*\.env[[:space:]]*$' pubspec.yaml | head -1 | cut -d: -f1)
  report env-asset pubspec.yaml "$l" ".env est publié dans l'APK et le build web (SEC-019, ADR-0009)."
fi

# 5. Android : identifiant d'exemple et signature debug en release (SEC-020)
if grep -nq 'applicationId = "com.example' android/app/build.gradle.kts 2>/dev/null; then
  l=$(grep -n 'applicationId = "com.example' android/app/build.gradle.kts | cut -d: -f1)
  report android-release android/app/build.gradle.kts "$l" "applicationId com.example.* refusé par Google Play (SEC-020)."
fi
if grep -nq 'signingConfigs.getByName("debug")' android/app/build.gradle.kts 2>/dev/null; then
  l=$(grep -n 'signingConfigs.getByName("debug")' android/app/build.gradle.kts | cut -d: -f1)
  report android-release android/app/build.gradle.kts "$l" "Build release signé avec la clé de debug (SEC-020)."
fi

# 6. dart:io hors fichiers dédiés *_io.dart (compatibilité Web, AMEL-011)
while IFS=: read -r f l _; do
  [[ -z "$f" || "$f" == *_io.dart ]] && continue
  report dart-io "$f" "$l" "dart:io casse la plateforme Web : utiliser XFile/bytes ou un import conditionnel (AMEL-011, ADR-0002)."
done < <(git grep -nE "^import 'dart:io'" -- 'lib/*.dart' 2>/dev/null || true)

# 7. Accès Supabase direct depuis la couche presentation (AMEL-002, ADR-0004)
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report presentation-supabase "$f" "$l" "La couche presentation ne doit pas importer supabase_flutter (AMEL-002)."
done < <(git grep -nE "^import 'package:supabase_flutter/" -- 'lib/features/*/presentation/*' 2>/dev/null || true)

# 8. Taille des fichiers Dart (maintenabilité, ADR-0006 : ≤ 400 lignes)
max_lines="${MAX_FILE_LINES:-400}"
while IFS= read -r f; do
  n=$(wc -l < "$f")
  if (( n > max_lines )); then
    report file-size "$f" "" "${n} lignes (> ${max_lines}) : découper le fichier (AMEL-001)."
  fi
done < <(tracked 'lib/*.dart' | grep -vE '\.(g|freezed)\.dart$')

# 9. print() dans lib/ (utiliser un logger)
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report no-print "$f" "$l" "print() interdit dans lib/ : utiliser le logger (AMEL-006)."
done < <(git grep -nE '(^|[^A-Za-z_.])print\(' -- 'lib/*.dart' 2>/dev/null || true)

# 10. TODO sans référence de ticket
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report todo-ticket "$f" "$l" "TODO sans ticket : écrire // TODO(ID-TICKET): ..."
done < <(git grep -nE '(//|#|--)[[:space:]]*(TODO|FIXME)(:|[[:space:]])' -- lib supabase test tool ':!tool/ci/check_repo_policies.sh' 2>/dev/null || true)

# 11. Exceptions brutes affichées à l'utilisateur (REL-008)
while IFS=: read -r f l _; do
  [[ -z "$f" ]] && continue
  report raw-error "$f" "$l" "Exception brute affichée à l'utilisateur : passer par la gestion d'erreurs centralisée (REL-008)."
done < <(git grep -nE "Text\(['\"][^'\"]*\\\$e['\"]" -- 'lib/*.dart' 2>/dev/null || true)

echo
echo "Politiques du dépôt : ${errors} erreur(s), ${warnings} avertissement(s)."
echo "Règles bloquantes : ${ERROR_RULES}"
(( errors == 0 ))
