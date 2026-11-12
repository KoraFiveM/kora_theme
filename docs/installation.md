---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Theme is the single source of colours, corner radius, shadows and font choices for every Kora NUI. The palette and shape live in `theme.json`; a small Lua loader validates them once per VM; every other resource with its own NUI frame imports `client/bridge.lua` and loads `theme.js`/`theme.css` to render with the same tokens. It also runs its own colour-picker NUI so players can choose a personal accent colour, saved client-side only.

## Install Kora Theme

1. **Add the folder** — Place `kora_theme` in your resources directory (on the Kora recipe it is `resources/[standalone]/kora_theme`). Keep the folder name `kora_theme`: every consumer's bridge file calls `exports['kora_theme']` and `exports[GetCurrentResourceName()]` by that literal name.

2. **Start it before anything with an NUI** — `kora_lib` itself depends on `kora_theme` for its AppShell styling, so `kora_theme` must start before `kora_lib` and before every resource that themes its own NUI with it (kora_banking, kora_bossmenu, kora_inventory, kora_cards, kora_hud, kora_multichar, kora_clothing, kora_phone, kora_emotemenu, kora_chat, and more).

3. **Edit theme.json — not config.lua** — Colours, the server's primary-colour label, extra colour-picker presets, corner radius and shadow style all live in `theme.json`, the single source of truth read by `theme_loader.lua` on both realms and by `theme.js` in the browser. `config.lua` only holds behaviour: whether players may pick their own accent colour, and which font each UI slot uses.

4. **Optional: add fonts** — `fonts/catalog.json` lists bundled fonts available by id (`inter`, `roboto`, `poppins`, `montserrat`, `rajdhani`, `oswald`, `exo-2` for sans; `jetbrains-mono`, `roboto-mono` for mono). `theme.json`'s `fonts` object, or `config.lua`'s `KoraThemeConfig.fonts` (editable live via kora_lib's `/config`), select by id, by `'default'`, or by a literal CSS font-family list.

## Manifest reference

`ui_page 'web/index.html'` is the colour-picker frame only (opened by `/theme`), not the theming mechanism itself: `theme.js` and `theme.css` are files every OTHER resource's own NUI page links directly from `cfx-nui-kora_theme`.

```lua title="fxmanifest.lua"
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_theme'
author 'qbcore2'
version '0.2.0'
description 'Shared design tokens and browser styling for qbcore2 resources'

ui_page 'web/index.html'

files {
    'theme.css', 'theme.js', 'theme.json', 'fonts/**',
    'web/index.html', 'web/app.js', 'web/style.css',
    'client/bridge.lua', 'vite-plugin.mjs',
}

shared_scripts {
    'theme_loader.lua',
    'config.lua',
    'shared.lua',
}

client_script 'client/main.lua'

qa_feature 'tests/*.feature'
```

- `vite-plugin.mjs` is a Vite dev-server plugin (not loaded by the manifest) that a consumer's own web project can import to serve `theme.css`/`theme.js`/`theme.json`/fonts from this resource's NUI origin during `vite dev`, and to version `theme.js`'s URL so a stale cached copy isn't retained across reconnects in production.

## Give your own NUI the same theme

Two separate integrations, used together by every first-party Kora NUI: `theme.js`/`theme.css` apply the CSS custom properties inside the browser page itself, while `client/bridge.lua` (copied into your resource's own client scripts) exposes `KoraTheme.apply()`/`KoraTheme.refresh()`/`KoraTheme.fonts()` so your Lua code can read the resolved tokens or push a resource-specific colour override.

```lua title="fxmanifest.lua"
-- In another resource's fxmanifest.lua (kora_emotemenu does this)
dependency 'kora_theme'

client_scripts {
    '@kora_theme/client/bridge.lua',
    'client/main.lua', -- your own NUI code, which calls KoraTheme.apply()/refresh()
}
```

- In your NUI's HTML, link `../theme.css` and load `../theme.js` the same way `web/index.html` does here; `theme.js` fetches this resource's `theme.json` (and `fonts/catalog.json` if fonts are configured) directly over `cfx-nui-kora_theme`, with up to 40 retries 250ms apart.
- `client/bridge.lua` is deliberately loaded into the CONSUMER's own Lua VM (not kora_theme's) so its NUI natives (`SendNUIMessage`) target that consumer's own frame. It reads tokens via `exports.kora_theme:getTokens(...)`/`getFonts()`.
- Confirmed consumers of this exact bridge file in the current recipe: kora_lib, kora_inventory, kora_cards, kora_hud, kora_multichar, kora_clothing, kora_phone, kora_emotemenu, kora_chat.

## Dependencies

`fxmanifest.lua` declares no dependencies. Optional integrations:

| Resource | Used for |
| --- | --- |
| `kora_lib` | Registers the live font settings for `/config`. `kora_lib` itself depends on `kora_theme`, so `kora_theme` cannot declare it; `config.lua` waits for `kora_lib` to start and loads `modules/config/consumer.lua` from it. Without `kora_lib` the resource still works and `KoraThemeConfig` stays a plain table. |
| `kora_chat` (or any resource providing `chat:addSuggestion`) | Shows the `/theme` suggestion. Suggestions are re-sent when `kora_chat` starts. |

There is no SQL and no item or ACE setup. Fonts need no extra setup because they ship in `fonts/`.

## What is not shipped

`config.local.lua` and `config.local.lua.bak` are ignored by git (see `.gitignore`); they are described there as generated per-server `kora_lib` configuration overrides.
