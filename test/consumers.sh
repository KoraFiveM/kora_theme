#!/usr/bin/env sh
set -eu

workspace=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
resources="$workspace/resources/[test]"
page_consumers="kora_cards kora_chat kora_clothing kora_hud kora_inventory kora_lib kora_loading kora_multichar kora_phone"
bridge_consumers="kora_cards kora_chat kora_clothing kora_hud kora_inventory kora_lib kora_multichar kora_phone"
headless_apps="kora_banking kora_dispatch kora_garages kora_multijob"
consumers="$page_consumers $headless_apps"

fail() {
  echo "kora_theme consumer check: $*" >&2
  exit 1
}

# kora_theme must be ensured before every consumer that is ensured directly in
# server.cfg. Consumers reached only via a category ensure (ensure [test]) or not
# ensured at all are not ordered here; their manifest dependency covers them.
cfg="$workspace/server.cfg"
if [ ! -f "$cfg" ]; then
  echo "kora_theme consumer check: skipped (no server.cfg at $cfg; run inside a server checkout)"
  exit 0
fi
theme_line=$(awk '$1 == "ensure" && $2 == "kora_theme" { print NR; exit }' "$cfg")
[ -n "$theme_line" ] || fail "server.cfg does not ensure kora_theme"
for resource in $consumers; do
  consumer_line=$(awk -v r="$resource" '$1 == "ensure" && $2 == r { print NR; exit }' "$cfg")
  [ -z "$consumer_line" ] || [ "$theme_line" -lt "$consumer_line" ] \
    || fail "kora_theme must be ensured before $resource"
done
ox_lib_ensure_count=$(awk '$1 == "ensure" && $2 == "ox_lib" { count++ } END { print count + 0 }' "$workspace/server.cfg")
[ "$ox_lib_ensure_count" -eq 0 ] || fail "server.cfg must not ensure optional ox_lib"
ox_lib_resource_count=$(find "$workspace/resources" -mindepth 2 -maxdepth 2 -type d -name ox_lib | wc -l)
[ "$ox_lib_resource_count" -eq 1 ] || fail "resources must contain exactly one ox_lib compatibility resource"
grep -Pzq ':where\(html, body\) \{[^}]*background:[[:space:]]*transparent[[:space:]]*!important' "$resources/kora_theme/theme.css" \
  || fail "kora_theme must keep document bodies transparent"
! grep -Eq 'color-scheme:[[:space:]]*dark' "$resources/kora_theme/theme.css" \
  || fail "kora_theme must not colour FiveM's transparent browser canvas"

for resource in $consumers; do
    root="$resources/$resource"
    manifest="$root/fxmanifest.lua"
    grep -Eq "dependency ['\"]kora_theme['\"]" "$manifest" || fail "$resource has no direct kora_theme dependency"
done

for resource in $bridge_consumers; do
  manifest="$resources/$resource/fxmanifest.lua"
  grep -Eq "@kora_theme/client/bridge\.lua" "$manifest" || fail "$resource does not import the kora_theme bridge"
done

for resource in kora_loading $headless_apps; do
  manifest="$resources/$resource/fxmanifest.lua"
  ! grep -Eq "@kora_theme/client/bridge\.lua" "$manifest" || fail "$resource must not import the kora_theme bridge without a persistent private UI frame"
done

for resource in $page_consumers; do
  root="$resources/$resource"
  if [ "$resource" = "kora_loading" ]; then
    source_html="$root/html/index.html"
    built_html="$source_html"
  else
    source_html="$root/web/index.html"
    built_html="$root/web/build/index.html"
    grep -Eq "import [A-Za-z_]+ from ['\"]\.\./\.\./kora_theme/vite-plugin\.mjs['\"]" "$root/web/vite.config.ts" || fail "$resource does not use kora_theme's Vite helper"
  fi

  grep -Eq "QBTHEME_BASE.*theme\.css|cfx-nui-kora_theme/theme\.css" "$source_html" || fail "$resource source HTML does not link theme.css"
  grep -Eq "QBTHEME_BASE.*theme\.js|cfx-nui-kora_theme/theme\.js" "$source_html" || fail "$resource source HTML does not load theme.js"
  [ -f "$built_html" ] || fail "$resource has no built HTML"
  grep -Eq "https://cfx-nui-kora_theme/theme\.css" "$built_html" || fail "$resource build copied or omitted theme.css"
  grep -Eq "https://cfx-nui-kora_theme/theme\.js" "$built_html" || fail "$resource build copied or omitted theme.js"
done

grep -Pzq 'html,[[:space:]]*\nbody \{[^}]*background:[[:space:]]*transparent[[:space:]]*!important' "$resources/kora_loading/html/style.css" \
  || fail "kora_loading must keep its document body transparent"
grep -Pzq '\.screen \{[^}]*background:[[:space:]]*transparent' "$resources/kora_loading/html/style.css" \
  || fail "kora_loading must not paint an opaque fullscreen screen"

reserved='--(background|foreground|card|card-foreground|popover|popover-foreground|primary|primary-foreground|secondary|secondary-foreground|muted|muted-foreground|accent|accent-foreground|destructive|danger|border|border-strong|input|ring|brand-hover|brand-pressed|brand-soft|brand-border|surface|surface-raised|surface-panel|surface-hover|control-border|control-border-hover|success|warning|info|armour|radius|shadow-low|shadow-floating|shadow-modal)[[:space:]]*:'
for resource in $page_consumers; do
  [ "$resource" = "kora_loading" ] && source_root="$resources/$resource/html" || source_root="$resources/$resource/web/src"
  if grep -rnE --include=*.css -- "$reserved" "$source_root"; then
    fail "$resource redefines reserved global tokens"
  fi
done

echo "kora_theme consumers: 13 resources verified"
