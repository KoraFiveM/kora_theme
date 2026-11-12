---
title: Events
sidebar_position: 9
---

# Events

`kora_theme` registers no net events and no server events. Everything below is client-local.

## Local events

| Event | Raised by | Listeners |
| --- | --- | --- |
| `kora_theme:fontsChanged` | `config.lua` when a font setting changes in `/config` | `client/main.lua` (updates the picker frame) and each consumer's `bridge.lua` (forwards the fonts to its frame). The script runs on both sides, so the trigger may also occur server-side. |
| `kora_theme:playerThemeChanged` | `client/main.lua` when the player colour changes | each consumer's `bridge.lua`, which re-reads the player colour and re-applies overrides |

It also listens to `onClientResourceStart` for `kora_theme` (bridge: re-sync the frame) and for `kora_chat` (re-send the chat suggestion), and to `onClientResourceStop` for itself (close the picker, remove the suggestion). On the config side, `onResourceStart` for `kora_lib` triggers registration of the font settings.

## NUI messages (Lua to page)

Handled by `theme.js` (origin must be `nui://game`):

| `action` | `data` | Effect |
| --- | --- | --- |
| `kora_theme:override` | `#RRGGBB` string, table of colours, or `nil` | Sets the primary or palette overrides and re-applies tokens. |
| `kora_theme:fonts` | the `getFonts` result | Applies server fonts. |
| `kora_theme:refresh` | none | Re-fetches `theme.json`. |

The picker page additionally handles `kora_theme:open`, `kora_theme:close` and `kora_theme:state`.

## NUI callbacks (page to Lua)

| Callback | Registered in | Behaviour |
| --- | --- | --- |
| `kora_theme:ready` | `client/main.lua` and each consumer's `bridge.lua` | Called by `theme.js` after loading `theme.json`. Returns `{ overrides, fonts }` (the picker frame also gets `picker`). |
| `kora_theme:set` | `client/main.lua` | Picker only. Body `{ colour }`; returns `{ ok, message, state }`. `colour` of `null` resets. |
| `kora_theme:close` | `client/main.lua` | Picker only. Closes the picker. |

## Page integration hook

A page without the Lua bridge (for example a loading screen) can set `window.KoraThemePagePrimary = "#RRGGBB"` (or `null`) and dispatch a `kora_theme:page-primary` event on `window`. A bridge override still wins over it.
