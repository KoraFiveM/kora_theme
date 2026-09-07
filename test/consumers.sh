#!/usr/bin/env sh
set -eu

workspace=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
resources="$workspace/resources/[test]"
page_consumers="qbcards qbchat qbclothing qbhud qbinventory qblib qbloading qbmultichar qbphone"
bridge_consumers="qbcards qbchat qbclothing qbhud qbinventory qblib qbmultichar qbphone"
headless_apps="qbbanking qbdispatch qbgarages qbmultijob"
consumers="$page_consumers $headless_apps"

fail() {
  echo "qbtheme consumer check: $*" >&2
  exit 1
}

first_ensure=$(awk '/^[[:space:]]*ensure[[:space:]]+/ { print $2; exit }' "$workspace/server.cfg")
[ "$first_ensure" = "qbtheme" ] || fail "qbtheme must be the first ensured resource"
rg -U -q ':where\(html, body\) \{[^}]*background:[[:space:]]*transparent[[:space:]]*!important' "$resources/qbtheme/theme.css" \
  || fail "qbtheme must keep document bodies transparent"
! rg -q 'color-scheme:[[:space:]]*dark' "$resources/qbtheme/theme.css" \
  || fail "qbtheme must not colour FiveM's transparent browser canvas"

for resource in $consumers; do
    root="$resources/$resource"
    manifest="$root/fxmanifest.lua"
    rg -q "dependency ['\"]qbtheme['\"]" "$manifest" || fail "$resource has no direct qbtheme dependency"
done

for resource in $bridge_consumers; do
  manifest="$resources/$resource/fxmanifest.lua"
  rg -q "@qbtheme/client/bridge\.lua" "$manifest" || fail "$resource does not import the qbtheme bridge"
done

for resource in qbloading $headless_apps; do
  manifest="$resources/$resource/fxmanifest.lua"
  ! rg -q "@qbtheme/client/bridge\.lua" "$manifest" || fail "$resource must not import the qbtheme bridge without a persistent private UI frame"
done

for resource in $page_consumers; do
  root="$resources/$resource"
  if [ "$resource" = "qbloading" ]; then
    source_html="$root/html/index.html"
    built_html="$source_html"
  else
    source_html="$root/web/index.html"
    built_html="$root/web/build/index.html"
    rg -q "qbtheme from ['\"]\.\./\.\./qbtheme/vite-plugin\.mjs['\"]" "$root/web/vite.config.ts" || fail "$resource does not use qbtheme's Vite helper"
  fi

  rg -q "QBTHEME_BASE.*theme\.css|cfx-nui-qbtheme/theme\.css" "$source_html" || fail "$resource source HTML does not link theme.css"
  rg -q "QBTHEME_BASE.*theme\.js|cfx-nui-qbtheme/theme\.js" "$source_html" || fail "$resource source HTML does not load theme.js"
  [ -f "$built_html" ] || fail "$resource has no built HTML"
  rg -q "https://cfx-nui-qbtheme/theme\.css" "$built_html" || fail "$resource build copied or omitted theme.css"
  rg -q "https://cfx-nui-qbtheme/theme\.js" "$built_html" || fail "$resource build copied or omitted theme.js"
done

rg -U -q 'html,[[:space:]]*\nbody \{[^}]*background:[[:space:]]*transparent[[:space:]]*!important' "$resources/qbloading/html/style.css" \
  || fail "qbloading must keep its document body transparent"
rg -U -q '\.screen \{[^}]*background:[[:space:]]*transparent' "$resources/qbloading/html/style.css" \
  || fail "qbloading must not paint an opaque fullscreen screen"

reserved='--(background|foreground|card|card-foreground|popover|popover-foreground|primary|primary-foreground|secondary|secondary-foreground|muted|muted-foreground|accent|accent-foreground|destructive|danger|border|border-strong|input|ring|brand-hover|brand-pressed|brand-soft|brand-border|surface|surface-raised|surface-panel|surface-hover|control-border|control-border-hover|success|warning|info|armour|radius|shadow-low|shadow-floating|shadow-modal)[[:space:]]*:'
for resource in $page_consumers; do
  [ "$resource" = "qbloading" ] && source_root="$resources/$resource/html" || source_root="$resources/$resource/web/src"
  if rg -n --glob '*.css' -- "$reserved" "$source_root"; then
    fail "$resource redefines reserved global tokens"
  fi
done

echo "qbtheme consumers: 13 resources verified"
