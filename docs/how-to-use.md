---
title: "How to use"
sidebar_position: 3
---


# How to use

Players interact with Kora Theme through one command, `/theme`, which opens a colour picker. Every other resource's NUI simply loads `theme.css`/`theme.js` and, optionally, `client/bridge.lua` to read resolved tokens from Lua.

## Player walkthrough

1. **Open the picker** — `/theme` with no argument opens the colour-picker NUI (disabled entirely if `KoraThemeConfig.playerTheme.enabled` is false). It shows the server's default colour as the first preset, any extra presets from `theme.json`'s `presets` list, and a custom HTML colour input.

2. **Choose or reset** — `/theme #7C3AED` sets a personal accent colour directly from chat; `/theme reset` (or choosing "Use server default" in the picker) clears it. The chosen colour is stored in client-side KVP storage (`kora_theme:playerTheme` by default) and never sent to the server or to other players.

3. **Every themed NUI updates live** — Changing the colour fires a local event (`kora_theme:playerThemeChanged`) that every resource's own copy of `client/bridge.lua` listens for, so every open NUI frame in that client's game updates immediately without a resource restart.

## How the palette resolves

- `theme.json`'s `colors` object is the full palette: `background`, `surface`, `surfacePopover`, `surfaceRaised`, `surfaceHover`, `foreground`, `mutedForeground`, `border`, `borderStrong`, `control`, `controlHover`, `primary`, `success`, `warning`, `danger`, `info`, `armour`. Every value must be a 6-digit `#RRGGBB` hex string or it is rejected (with a console warning) in favour of a built-in emergency fallback for that one colour.
- `theme_loader.lua` runs once per VM (client and server each load their own copy) and exposes the validated result as the global `KoraThemeFile`. If `theme.json` is missing, unreadable, or not valid JSON with a `colors` object, the WHOLE palette falls back to a built-in emergency dark theme and a warning is printed — the resource never fails to start over a bad theme file.
- `shared.lua`'s `getTokens`/`getColours` turn the six-digit hex colours into the actual CSS custom properties consumed by Kora NUIs (backgrounds, borders, brand/success/warning/destructive/info variants, soft/border tints, contrast-aware foreground text, spacing, radius, shadows, durations). Nearly every derived token is computed as an HSL triple from the base hex so NUIs can apply alpha with `hsl(var(--x) / 50%)`.
- `primary-foreground` (and the `success`/`warning`/`destructive`/`info` foregrounds) are chosen between white and a fixed dark grey by relative-luminance contrast (`contrastToken`/`contrast` — WCAG-style, not just a brightness threshold), so a very light configured `primary` still gets readable text on top of it.

## Shape: radius and shadows

`theme.json`'s optional `shape` object controls corner radius (`radius`, 0–24 px, rounded to the nearest integer; `radius-sm`/`radius-lg` are derived as 0.75x/1.25x) and shadow depth (`shadows`: `'none'` for a literal zero-shadow set that still works inside a comma-joined `box-shadow` list, or `'soft'` for softer, shallower shadows than the built-in default). An invalid or missing `shape` silently keeps `theme.css`'s own defaults; invalid fields are warned about once each and ignored individually, not server-wide.

## Fonts

- Three slots: `body`, `heading`, `mono`. Resolution order per slot: a `/config` custom font-family string (if set and valid) → a `/config` dropdown choice other than `'theme'` (a `fonts/catalog.json` id) → `theme.json`'s `fonts.<slot>` value → the built-in default stack. A heading left on 'default' follows the resolved body font rather than using its own separate default.
- `/config`'s custom-family fields accept only letters, digits, spaces, commas, quotes and hyphens with balanced quotes (`^[%w ,'"%-]*$`, 200 characters max) — this blocks `url(...)`, `var(...)` and anything else that could break out of a CSS value, both in the Lua validator and in `theme.js`'s matching browser-side check.
- Changing a font in kora_lib's `/config` fires the local event `kora_theme:fontsChanged`, which every consumer's `client/bridge.lua` (and this resource's own picker frame) forwards to its NUI as `{ action: 'kora_theme:fonts' }`, so a font change applies to every open UI without a restart.

## Reading tokens from Lua

```lua title="server.lua or client.lua"
-- Server or client: read the resolved design tokens for a custom override
local tokens = exports.kora_theme:getTokens({ primary = '#3B82F6' })
print(tokens.primary) -- "217.2 91.2% 59.8%" (an HSL triple, space-separated, for CSS hsl())
```

## Applying the theme to your own NUI from Lua

```lua title="client/main.lua"
-- client/main.lua, after requiring client/bridge.lua as a client script
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    KoraTheme.apply() -- sends the current override (none, by default) to your NUI frame
end)
```
