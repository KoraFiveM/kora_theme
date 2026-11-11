#!/usr/bin/env sh
set -eu
lua_bin="${LUA:-lua}"
"$lua_bin" "$(dirname "$0")/theme.lua"
"$lua_bin" "$(dirname "$0")/client.lua"
"$lua_bin" "$(dirname "$0")/bridge.lua"
"$lua_bin" "$(dirname "$0")/config.lua"
node "$(dirname "$0")/theme-js.cjs"
node "$(dirname "$0")/vite-plugin.mjs"
"$(dirname "$0")/consumers.sh"
