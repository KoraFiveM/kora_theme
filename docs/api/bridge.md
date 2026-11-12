---
title: "Client bridge (KoraTheme)"
sidebar_position: 3
---


# Client bridge (KoraTheme)

A small file every themed Kora NUI includes as its own client script (see Installation → "Give your own NUI the same theme"). It deliberately runs inside the consumer's own Lua VM so its `SendNUIMessage` calls reach that consumer's own frame, not kora_theme's.

Namespace: `KoraTheme (global, after requiring client/bridge.lua)` · Source: `client/bridge.lua (copied as a client script into the CONSUMING resource, not run inside kora_theme)`

## How it works

On load it reads the player's personal override once (`readPlayerOverride`, via `exports.kora_theme:getPlayerTheme()`). It re-reads and re-applies automatically on `kora_theme:playerThemeChanged` (the player ran `/theme`) and on kora_theme's own `onClientResourceStart` (a kora_theme restart). It also answers the NUI's own `kora_theme:ready` POST callback with `{ overrides, fonts }` so a fresh page load gets the current state without waiting for an event.

## Terms used on this page

| Term | Meaning |
| --- | --- |
| Effective override | The consumer's own override (set via `KoraTheme.apply(overrides)`) merged with the player's personal `/theme` colour: if the consumer passed a table without its own `primary`, the player's colour fills that slot; a consumer-set `primary` always wins over the player's choice for that one UI. |

## Functions

Four functions on the global `KoraTheme` table.

### `KoraTheme.apply(overrides?)`

Pushes a resource-specific colour override (or clears it) to THIS consumer's own NUI frame and returns the resolved tokens.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `overrides?` | string \| table \| nil | Same shape as `getTokens`'s override; `nil` clears any previous override set by this consumer. |

**Returns**

- **`table`** — the resolved token map (same shape as `exports.kora_theme:getTokens(...)`), for callers that also want the values in Lua.

**Example**

```lua
KoraTheme.apply({ primary = '#3B82F6' }) -- e.g. a job-specific accent for this one UI
```

**Representative console output**

```text
Sends `{ action: 'kora_theme:override', data: <effective override> }` to the consumer's own frame, merging in the player's personal `/theme` colour unless the consumer's own override already names a `primary`. Does NOT send the full token map — the browser reads the base palette directly from `theme.json` itself, since `LoadResourceFile` is unavailable in the browser.
```

### `KoraTheme.refresh()`

Tells the consumer's own NUI frame to reload `theme.json` from scratch (picks up a changed file without restarting the resource) and returns the resolved tokens.

**Parameters**



**Returns**

- **`table`** — the resolved token map.

**Example**

```lua
KoraTheme.refresh()
```

**Representative console output**

```text
Sends `{ action: 'kora_theme:refresh' }`; the browser's `theme.js` re-fetches `theme.json` and re-applies shape, colours and fonts.
```

### `KoraTheme.tokens()`

Reads the resolved tokens without sending anything to the NUI.

**Parameters**



**Returns**

- **`table`** — same shape as `KoraTheme.apply`'s return value, or `{}` if the `kora_theme` export call failed (for example if kora_theme is not running).

**Example**

```lua
local tokens = KoraTheme.tokens()
```

**Representative console output**

```text
Wraps the `getTokens` export call in `pcall` and logs `[<resource>] could not read kora_theme tokens: ...` on failure rather than erroring.
```

### `KoraTheme.fonts()`

Resolved server fonts (theme.json plus any `/config` overrides), for pushing to the consumer's own NUI.

**Parameters**



**Returns**

- **`table | nil`** — same shape as `exports.kora_theme:getFonts()`'s return value, or `nil` on failure.

**Example**

```lua
local fonts = KoraTheme.fonts()
```

**Representative console output**

```text
Also wrapped in `pcall`.
```

## Limits and related APIs

Each resource that imports this file gets its own independent copy of its module-local state (`currentOverrides`, `playerOverride`) — calling `KoraTheme.apply()` in one resource has no effect on another resource's NUI.

## Related guides

- [Design-token exports](./exports.md)

## Additional notes

- `KoraTheme.tokens` is the local function that reads `getTokens` with the current effective overrides and ignores any arguments passed to it. It returns `{}` and prints a message if the export is unavailable.
- `KoraTheme.refresh()` sends `kora_theme:refresh`, which makes `theme.js` re-fetch `theme.json`. It does not re-send the override.
- A saved player colour is used only for the primary and does not replace a consumer-owned override.
- Events and NUI callbacks used by the bridge are listed on [Events](../events.md).
