# kora_theme

Shared dark design system for qbcore2 browser UIs. Start this resource before
all UI resources and declare `dependency 'kora_theme'` in each consumer.

Browser pages load `https://cfx-nui-kora_theme/theme.css` and `theme.js`. Resources
with a persistent private UI frame import `@kora_theme/client/bridge.lua` for live
refresh behavior. A loading screen whose frame is permanently shut down does
not keep that Lua bridge, and headless AppShell consumers pass their accent to
kora_lib instead of sending NUI messages from their own resource.

## One source of truth: theme.json

**Server owners only ever edit `theme.json`, then restart `kora_theme`.** No
generation or build step is needed.

| Consumer | How it reads `theme.json` |
| --- | --- |
| Lua exports (`getTokens`, `getPrimaryColor`), `/theme` picker default | `theme_loader.lua` (first shared script) reads it with `LoadResourceFile` + `json.decode` on server and client; `shared.lua` and `client/main.lua` use the result. |
| Browser colours (CSS variables) | `theme.js` fetches `theme.json` and sets every colour variable on `:root`. |
| Browser fonts | `theme.js` resolves `theme.json`'s `fonts` against `fonts/catalog.json` and sets `--font-sans`, `--font-heading` and `--font-mono`. |
| `theme.css` | Contains no colours, only fixed tokens (default fonts, spacing, radius, shadows, motion) and component rules. It imports `fonts/fonts.css`. |
| Vite dev server | `vite-plugin.mjs` serves `theme.json` and `fonts/` (and `theme.js` reads the copy next to itself). |

`config.lua`, `theme.css` and `theme.js` hold no colour values. Pages must load
`theme.js` alongside `theme.css`; until it has loaded `theme.json` the colour
variables are unset. The only built-in colours are the emergency defaults in
`theme_loader.lua`, used (with a `^3[kora_theme]` console warning) when
`theme.json` is missing or invalid, or per key when one value is not `#RRGGBB`.

`theme.json` keys: `colors` (the semantic palette), `shape` (corners and
shadows, below), `name` (label of the primary
colour, shown as the first picker preset), `presets` (extra `/theme` picker
colours, each `{ "label", "colour" }`) and `fonts` (see below).

The default primary is Kora green `#95FF00`; the contrast token puts dark text
on it. Running UI resources receive the new tokens without being restarted. A
consumer that owns an approved accent can call `KoraTheme.apply('#RRGGBB')`;
`KoraTheme.refresh()` reapplies the cached override; `KoraTheme.fonts()` returns
the resolved server fonts.

## Shape (corners and shadows)

```json
"shape": { "radius": 8, "shadows": "soft" }
```

- `radius`: base corner size in px (0 to 24). Small and large corners scale from it.
- `shadows`: `"soft"` (light shadows on menus and dialogs) or `"none"`.

Both are optional; leaving `shape` out keeps the old look (10px corners, heavier
shadows). Every UI reads `--radius`, `--radius-sm`, `--radius-lg` and
`--shadow-low/floating/modal`, so these two values restyle all of them.

## Fonts

UIs use three CSS variables: `--font-sans` (body text), `--font-heading`
(`h1`–`h6` through a zero-specificity `:where()` rule, and any element using
`var(--font-heading)`) and `--font-mono`. Their `theme.css` defaults are the
original stacks (`Inter, ui-sans-serif, system-ui, …` and
`"SFMono-Regular", Consolas, …`), so nothing changes until a font is chosen.

```json
"fonts": { "heading": "oswald", "body": "poppins", "mono": "default" }
```

Each value is `"default"`, an id from `fonts/catalog.json`, or a plain CSS
font-family list such as `"Arial, sans-serif"`. A default heading uses the
body font. Custom lists may only contain letters, digits, spaces, commas,
quotes and hyphens (200 characters at most, balanced quotes); the slot's
default stack is appended as a fallback. An invalid value logs a
`^3[kora_theme]` warning and falls back to the default.

Bundled fonts (OFL-1.1, latin subset, local woff2 from `@fontsource`; each
folder holds its `OFL.txt`):

| id | Font | Kind |
| --- | --- | --- |
| `inter` | Inter | sans |
| `roboto` | Roboto | sans |
| `poppins` | Poppins | sans |
| `montserrat` | Montserrat | sans |
| `rajdhani` | Rajdhani | sans |
| `oswald` | Oswald | sans |
| `exo-2` | Exo 2 | sans |
| `jetbrains-mono` | JetBrains Mono | mono |
| `roboto-mono` | Roboto Mono | mono |

The `@font-face` families have a `Kora ` prefix (`"Kora Poppins"`), so the
default stack's `Inter` keeps resolving exactly as before. Browsers only
download a font file once a stack uses it.

### Changing fonts in game (/config)

Admins with the `kora_lib.config.edit` ACE can open `/config` → **kora_theme**
→ **fonts** and pick **Body font**, **Heading font** and **Monospace font**
from dropdowns. **Server default (theme.json)** (the default) follows
`theme.json`. With **Advanced** on, **Custom … font family** text fields
accept a font-family list that overrides the dropdown for that slot (the font
must be installed on the player's PC or bundled here). These settings are
stored in `KoraThemeConfig.fonts` (`config.local.lua`) and apply live.

Precedence per slot: custom family > dropdown > `theme.json` > built-in default.

Live path: kora_lib syncs the change to every client → `config.lua` raises the
local `kora_theme:fontsChanged` event → each consumer's `client/bridge.lua` sends
`kora_theme:fonts` (the `getFonts()` result) to its NUI frame → `theme.js` sets
the variables. The `kora_theme:ready` callback also returns `fonts`, so newly
opened UIs pick up the admin choice; bridge-free pages (loading screens)
follow `theme.json`.

### Adding a font

1. Copy an OFL-licensed latin `woff2` (variable if available) and its licence
   to `fonts/<id>/` (`<id>` is lowercase letters, digits and hyphens).
2. Add an `@font-face` rule to `fonts/fonts.css` with a `Kora <Name>` family,
   a relative `url("<id>/<file>.woff2")` and `font-display: swap`.
3. Add `{ "id", "label", "kind": "sans" | "mono", "family", "stack" }` to
   `fonts/catalog.json`; the stack starts with the family and ends with the
   matching default stack. It then appears in `theme.json` and `/config`.

## Player themes

Player themes are enabled by default in `KoraThemeConfig.playerTheme`. Running
`/theme` opens the colour picker; `/theme #7C3AED` applies a colour directly,
and `/theme reset` restores the server default. The selected primary colour is
saved in client KVP storage, so it follows the player's game installation and
is not written to the character database or sent to the server.

`reset` returns to the primary in `theme.json`. Set
`KoraThemeConfig.playerTheme.enabled = false` to disable personal themes. The
command name and KVP key can be changed in `config.lua`; picker presets come
from `theme.json`.
Consumer-owned overrides passed through `KoraTheme.apply` still take precedence
over the player's general preference.

## Exports

- `exports.kora_theme:getTokens(overrides?)`
- `exports.kora_theme:getPrimaryColor()`
- `exports.kora_theme:getColours(overrides?)` → resolved `#RRGGBB` palette keyed like `theme.json`'s `colors`
- `exports.kora_theme:getFonts()` → `{ body, heading, mono }`, each
  `{ id, label, stack, source }` (`source` is `config`, `theme.json` or `default`)
- `exports.kora_theme:getPlayerTheme()` (client)
- `exports.kora_theme:setPlayerTheme(colour?)` (client)

`getTokens` accepts a primary-colour string or a table containing any keys
from `theme.json`'s `colors`. Invalid values are ignored and logged once. Its
complete map also contains the resolved `font-sans`, `font-heading` and
`font-mono` stacks and the fixed spacing, radius, shadow,
focus, selection, and motion tokens defined by `theme.css`.
