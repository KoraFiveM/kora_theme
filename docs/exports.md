---
title: Exports
sidebar_position: 7
---

# Exports

## Shared (client and server)

Registered in `shared.lua`.

| Export | Returns |
| --- | --- |
| `getTokens(overrides?)` | Map of token name to value (see [Design tokens](./tokens.md)). `overrides` is a `#RRGGBB` string (the primary) or a table with any keys from `theme.json` `colors`. Invalid values are ignored and logged once. |
| `getColours(overrides?)` | Resolved `#RRGGBB` palette keyed like `theme.json` `colors`. Same overrides. |
| `getFonts()` | `{ body, heading, mono }`, each `{ id, label, stack, source }` where `source` is `config`, `theme.json` or `default`. |
| `getPrimaryColor()` | The primary colour from `theme.json` (`#RRGGBB`). |

```lua
local tokens = exports.kora_theme:getTokens('#7C3AED')
local primary = exports.kora_theme:getPrimaryColor()
```

## Client only

Registered in `client/main.lua`.

| Export | Description |
| --- | --- |
| `getPlayerTheme()` | The player's saved primary colour as `#RRGGBB`, or `nil` (also `nil` when player themes are disabled). |
| `setPlayerTheme(colour?)` | Saves a colour, or resets it when given `nil`, `''`, `'reset'` or `'default'`. Returns `true`, or `false` plus an error message. Raises the local event `kora_theme:playerThemeChanged`. |

## KoraTheme bridge API

`@kora_theme/client/bridge.lua` is imported by a consumer's `client_scripts` and runs in the consumer's own Lua VM. It defines the global `KoraTheme`:

| Function | Description |
| --- | --- |
| `KoraTheme.apply(overrides?)` | Stores a consumer-owned override (a primary colour string or a table of colours) and sends it to the consumer's NUI frame as `kora_theme:override`. Returns the token map. A saved player colour is used only for the primary and does not replace a consumer-owned override. |
| `KoraTheme.refresh()` | Sends `kora_theme:refresh`, which makes `theme.js` re-fetch `theme.json`. Returns the token map. It does not re-send the override. |
| `KoraTheme.tokens(overrides?)` | Note: `KoraTheme.tokens` is the local function that reads `getTokens` with the current effective overrides and ignores its arguments. Returns `{}` and prints a message if the export is unavailable. |
| `KoraTheme.fonts()` | Resolved server fonts (`getFonts`), or `nil` if unavailable. |
