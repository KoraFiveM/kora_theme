---
title: "Player colour picker"
sidebar_position: 4
---


# Player colour picker

The `/theme` command and its NUI (presets grid, a native HTML colour input, Apply/Reset/Done). Entirely self-contained to this resource: it does not reuse `client/bridge.lua`, since there is nothing to bridge INTO — this is kora_theme's own frame.

Namespace: `exports.kora_theme (client), /theme` · Source: `client/main.lua, web/index.html, web/app.js, web/style.css`

## How it works

The first preset shown is always the server's configured primary colour (labelled from `theme.json`'s `name`, or `'Server default'`); further presets come from `theme.json`'s `presets` array. Duplicate colours (by normalised hex) are not shown twice. The NUI authors at 1920x1080 and scales uniformly to the player's actual resolution, matching every other first-party Kora NUI frame.

## Terms used on this page

| Term | Meaning |
| --- | --- |
| KVP storage | FiveM's per-client resource key-value storage (`SetResourceKvp`/`GetResourceKvpString`). Nothing about a player's chosen colour is ever sent to the server or to any other client. |

## Known fix carried in this doc pass

The picker's `.panel` rule in `web/style.css` now sets `max-height: calc(100vh - 2rem)` and `overflow-y: auto` directly in the base (non-media-query) rule, not only inside the narrow-screen media query — so a long preset/extra-text list no longer overflows the dialog on a normal-width screen, only the padding and width shrink further under the narrow-screen breakpoint.

## Functions

Two exports, client-only (there is no server-side player-theme state — the value lives entirely in that client's own KVP storage).

### `exports.kora_theme:getPlayerTheme()`

The current player's personal accent colour override, read from KVP storage.

**Parameters**



**Returns**

- **`string | nil`** — a `#RRGGBB` hex value, or `nil` when player themes are disabled or the player has not set one.

**Example**

```lua
local colour = exports.kora_theme:getPlayerTheme()
```

**Representative console output**

```text
Called by `client/bridge.lua`'s `readPlayerOverride` in every consuming resource, and by this resource's own `/theme` command.
```

### `exports.kora_theme:setPlayerTheme(value)`

Sets or clears the current player's personal accent colour.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `value` | string \| nil | A `#RRGGBB` (or bare 6-hex-digit) colour, or `nil`/`''`/`'reset'`/`'default'` to clear the override. |

**Returns**

- **`boolean ok, string|nil message`** — `false, 'Player themes are disabled on this server.'` if `KoraThemeConfig.playerTheme.enabled` is false; `false, 'Use a six-digit hex colour such as #7C3AED, or reset.'` for an invalid value; otherwise `true`.

**Example**

```lua
local ok, err = exports.kora_theme:setPlayerTheme('#3B82F6')
```

**Representative console output**

```text
Persists to `SetResourceKvp`/`DeleteResourceKvp` under `KoraThemeConfig.playerTheme.kvpKey`, then fires `kora_theme:playerThemeChanged` and pushes `kora_theme:override`/`kora_theme:state` to this resource's own picker NUI.
```

## Limits and related APIs

Client-only; a personal theme cannot be read, set, or audited from server code, and does not survive moving to a different PC (KVP storage is local to that FiveM client install).

## Related guides

- [Client bridge (KoraTheme)](./bridge.md)

## Additional notes

`setPlayerTheme` raises the local event `kora_theme:playerThemeChanged`. See [Events](../events.md) and the [picker window](../ui.md).
