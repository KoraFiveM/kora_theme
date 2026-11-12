---
title: "Design-token exports"
sidebar_position: 2
---


# Design-token exports

## Server

Four exports, registered identically on both client and server since `shared.lua` is a shared script. They are pure functions of `theme.json`, `fonts/catalog.json`, and `config.lua`'s font choice — no state is written by calling them.

Namespace: `exports.kora_theme` · Source: `shared.lua, theme_loader.lua`

### How it works

`resolveColours` validates any override against `^#%x%x%x%x%x%x$` and silently keeps the configured colour (with a one-time warning) for anything invalid. Colour tokens are derived as HSL triples; several (brand-hover/pressed, soft/border tints) apply a fixed lightness or alpha offset to the base colour rather than being separately configurable.

### Functions

Four exports, identical on both realms.

#### `exports.kora_theme:getTokens(overrides?)`

Resolves the full set of CSS custom properties (colours, fonts, spacing, radius, shadows, durations) a Kora NUI applies to `:root`.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `overrides?` | string \| table | Optional. A single hex string overrides just `primary`. A table may override any key present in `theme.json`'s `colors` object by name; an invalid (non-#RRGGBB) override value is ignored (with a one-time console warning) and the configured colour is kept instead. |

**Returns**

- **`table<string, string>`** — a flat map of CSS variable name (without the leading `--`) to its value, ready for `root.style.setProperty`.

**Example**

```lua
local tokens = exports.kora_theme:getTokens()
print(tokens.radius) -- "8px"
```

**Representative console output**

```text
Font tokens (`font-sans`, `font-heading`, `font-mono`) reflect the current `/config` and `theme.json` font resolution, not just theme.json's raw value.
```

#### `exports.kora_theme:getColours(overrides?)`

Resolves the raw palette as `#RRGGBB` strings, keyed exactly like `theme.json`'s `colors` object.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `overrides?` | string \| table | Optional. A single hex string overrides just `primary`. A table may override any key present in `theme.json`'s `colors` object by name; an invalid (non-#RRGGBB) override value is ignored (with a one-time console warning) and the configured colour is kept instead. |

**Returns**

- **`table<string, string>`** — e.g. `{ primary = '#95FF00', background = '#101010', ... }`.

**Example**

```lua
local colours = exports.kora_theme:getColours()
print(colours.primary)
```

**Representative console output**

```text
Useful when a consumer needs a plain hex value (for a canvas, a chat colour code, etc.) rather than a CSS token.
```

#### `exports.kora_theme:getFonts()`

Resolves the three font slots (`body`, `heading`, `mono`) through the full precedence chain (custom family → `/config` dropdown → `theme.json` → built-in default).

**Parameters**



**Returns**

- **`table`** — `{ body, heading, mono }`, each `{ id, label, stack, source }`. `source` is one of `'config'`, `'theme.json'`, or `'default'`; a `'default'` entry gets the built-in stack for its slot kind (the heading slot follows the resolved body stack).

**Example**

```lua
local fonts = exports.kora_theme:getFonts()
print(fonts.body.source) -- "theme.json", "config" or "default"
```

**Representative console output**

```text
Called by every consumer's `client/bridge.lua` (`KoraTheme.fonts()`) to push resolved fonts to its own NUI.
```

#### `exports.kora_theme:getPrimaryColor()`

The server-configured primary colour, unaffected by any override.

**Parameters**



**Returns**

- **`string`** — the `#RRGGBB` value of `theme.json`'s `colors.primary` (or the emergency fallback).

**Example**

```lua
local primary = exports.kora_theme:getPrimaryColor()
```

**Representative console output**

```text
Does not reflect a player's personal `/theme` override; use `getColours`/`getTokens` with that override applied for the effective colour a given client sees.
```

### Limits and related APIs

Calling these does not change anything: to actually show a different colour in a particular NUI, a consumer still has to push the result to that NUI via `SendNUIMessage` (which is exactly what `client/bridge.lua`'s `KoraTheme.apply()` does).

### Related guides

- [Client bridge (KoraTheme)](./bridge.md)
- [Player colour picker](./picker.md)

## Client

Same four exports as the server realm (shared script).

Namespace: `exports.kora_theme` · Source: `shared.lua, theme_loader.lua`

### How it works

On the client, `theme_loader.lua`'s `LoadResourceFile` calls read this resource's own files from the client cache, so the client-side palette matches the server's `theme.json` as long as the file itself matches (as it does once both are loaded from the same resource folder).

### Functions

Four exports, identical to the server realm.

#### `exports.kora_theme:getTokens(overrides?)`

Resolves the full set of CSS custom properties (colours, fonts, spacing, radius, shadows, durations) a Kora NUI applies to `:root`.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `overrides?` | string \| table | Optional. A single hex string overrides just `primary`. A table may override any key present in `theme.json`'s `colors` object by name; an invalid (non-#RRGGBB) override value is ignored (with a one-time console warning) and the configured colour is kept instead. |

**Returns**

- **`table<string, string>`** — a flat map of CSS variable name (without the leading `--`) to its value, ready for `root.style.setProperty`.

**Example**

```lua
local tokens = exports.kora_theme:getTokens()
print(tokens.radius) -- "8px"
```

**Representative console output**

```text
Font tokens (`font-sans`, `font-heading`, `font-mono`) reflect the current `/config` and `theme.json` font resolution, not just theme.json's raw value.
```

#### `exports.kora_theme:getColours(overrides?)`

Resolves the raw palette as `#RRGGBB` strings, keyed exactly like `theme.json`'s `colors` object.

**Parameters**

| Name | Type | Description |
| --- | --- | --- |
| `overrides?` | string \| table | Optional. A single hex string overrides just `primary`. A table may override any key present in `theme.json`'s `colors` object by name; an invalid (non-#RRGGBB) override value is ignored (with a one-time console warning) and the configured colour is kept instead. |

**Returns**

- **`table<string, string>`** — e.g. `{ primary = '#95FF00', background = '#101010', ... }`.

**Example**

```lua
local colours = exports.kora_theme:getColours()
print(colours.primary)
```

**Representative console output**

```text
Useful when a consumer needs a plain hex value (for a canvas, a chat colour code, etc.) rather than a CSS token.
```

#### `exports.kora_theme:getFonts()`

Resolves the three font slots (`body`, `heading`, `mono`) through the full precedence chain (custom family → `/config` dropdown → `theme.json` → built-in default).

**Parameters**



**Returns**

- **`table`** — `{ body, heading, mono }`, each `{ id, label, stack, source }`. `source` is one of `'config'`, `'theme.json'`, or `'default'`; a `'default'` entry gets the built-in stack for its slot kind (the heading slot follows the resolved body stack).

**Example**

```lua
local fonts = exports.kora_theme:getFonts()
print(fonts.body.source) -- "theme.json", "config" or "default"
```

**Representative console output**

```text
Called by every consumer's `client/bridge.lua` (`KoraTheme.fonts()`) to push resolved fonts to its own NUI.
```

#### `exports.kora_theme:getPrimaryColor()`

The server-configured primary colour, unaffected by any override.

**Parameters**



**Returns**

- **`string`** — the `#RRGGBB` value of `theme.json`'s `colors.primary` (or the emergency fallback).

**Example**

```lua
local primary = exports.kora_theme:getPrimaryColor()
```

**Representative console output**

```text
Does not reflect a player's personal `/theme` override; use `getColours`/`getTokens` with that override applied for the effective colour a given client sees.
```

### Limits and related APIs

Same as the server realm.

### Related guides

- [Client bridge (KoraTheme)](./bridge.md)
- [Player colour picker](./picker.md)

## Additional reference

- `getFonts()` always returns a `stack` for each slot: when the font resolves to `default`, the built-in stack for the slot kind is filled in, and `heading` follows the resolved `body` stack. `source` is `config`, `theme.json` or `default`.
- `getTokens` and `getColours` accept the override either as a `#RRGGBB` string (primary) or a table with any keys from `theme.json` `colors`. See [Design tokens](../tokens.md).
- Client-only exports `getPlayerTheme` and `setPlayerTheme` are documented on [Player colour picker](./picker.md).

```lua
local tokens = exports.kora_theme:getTokens('#7C3AED')
local primary = exports.kora_theme:getPrimaryColor()
```
