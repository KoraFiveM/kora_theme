---
title: Using the theme in a UI
sidebar_position: 9
---

# Using the theme in a UI

## Browser pages

Load both files; colours are unset until `theme.js` has fetched `theme.json`:

```html
<link rel="stylesheet" href="https://cfx-nui-kora_theme/theme.css" />
<script src="https://cfx-nui-kora_theme/theme.js" defer></script>
```

`theme.js` retries fetching `theme.json` up to 40 times at 250 ms intervals, applies the palette, shape and fonts, then (when `GetParentResourceName` exists) posts `kora_theme:ready` to its own resource to obtain the player's colour, any consumer override and the resolved fonts. It exposes `window.KoraTheme` with `applyTokens(tokens)` and `refresh()`.

`theme.css` contains no colours. It defines fixed tokens (fonts, spacing, radius, shadows, motion) and zero-specificity `:where()` rules for base elements, so consumer styles win. See [Design tokens](./tokens.md).

## Lua bridge

For a resource with a persistent private UI frame, import the bridge and declare the dependency:

```lua
dependency 'kora_theme'
client_script '@kora_theme/client/bridge.lua'
```

The bridge answers `kora_theme:ready`, forwards the player colour and font changes, and offers `KoraTheme.apply`. See [Exports](./exports.md) and [Events](./events.md).

Do not import the bridge in a resource whose frame is permanently shut down (a loading screen) or in headless apps that do not own a frame. The bundled `test/consumers.sh` enforces this for the Kora workspace: `kora_loading`, `kora_banking`, `kora_dispatch`, `kora_garages` and `kora_multijob` must not import it, and page consumers must declare the dependency. Bridge-free pages follow `theme.json` only (plus `window.KoraThemePagePrimary`).

## Scaling

The picker page scales a 1920x1080 layout to the window; consumers do the same on their own.
