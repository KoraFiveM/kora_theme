---
title: kora_theme
sidebar_position: 1
---

# kora_theme

`kora_theme` is the shared design system for Kora browser (NUI) interfaces. It provides one stylesheet (`theme.css`), one runtime script (`theme.js`), a single palette file (`theme.json`), a set of bundled fonts, a Lua bridge that consumer resources import, a Vite helper plugin, and a small player-facing `/theme` colour picker.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **One source of truth** - server owners edit `theme.json` (colours, shape, fonts, picker presets) and restart `kora_theme`. There is no build step. See [theme.json](./theme-json.md).
- **Browser runtime** - pages load `https://cfx-nui-kora_theme/theme.css` and `theme.js`; `theme.js` fetches `theme.json` and sets CSS variables on the root element. See [Using the theme in a UI](./integration.md).
- **Bundled fonts** - nine OFL-licensed fonts selectable by id, with optional custom font-family lists. See [Fonts](./fonts.md).
- **Player themes** - `/theme` lets each player choose a personal primary colour, stored client-side. See [Commands](./commands.md) and [Player theme picker](./ui.md).
- **Live font control** - admins can change fonts in kora_lib's `/config` and every open UI updates. See [Configuration](./configuration.md).
- **Lua exports** - resolved tokens, palette, fonts and the player colour. See [Exports](./exports.md).
- **Vite plugin** - serves the theme files in a Vite dev server and rewrites production URLs. See [Vite plugin](./vite-plugin.md).

## Pages

- [Installation](./installation.md) - start order, dependencies and consumer setup
- [theme.json](./theme-json.md) - palette, shape, presets and name
- [Fonts](./fonts.md) - bundled fonts, custom families, adding a font
- [Configuration](./configuration.md) - `config.lua` options and the `/config` font settings
- [Commands](./commands.md) - the `/theme` command
- [Exports](./exports.md) - Lua exports and the `KoraTheme` bridge API
- [Events](./events.md) - local events and NUI messages and callbacks
- [Using the theme in a UI](./integration.md) - loading the CSS/JS and the bridge in a consumer resource
- [Design tokens](./tokens.md) - CSS variables and component rules
- [Player theme picker](./ui.md) - the picker window
- [Vite plugin](./vite-plugin.md) - helper plugin for Vite-based UIs
- [Testing](./testing.md) - the bundled test scripts
- [Troubleshooting](./troubleshooting.md) - common problems

This resource has no server-side behaviour beyond exports, registers no database tables, no items, no net events and no ACE permissions of its own (the `/config` fonts editor uses `kora_lib`'s permission, see [Configuration](./configuration.md)).
