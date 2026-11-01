# kora_theme

Shared dark design system for qbcore2 browser UIs. Start this resource before
all UI resources and declare `dependency 'qbtheme'` in each consumer.

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
| `theme.css` | Contains no colours, only fixed tokens (fonts, spacing, radius, shadows, motion) and component rules. |
| Vite dev server | `vite-plugin.mjs` serves `theme.json` (and `theme.js` reads the copy next to itself). |

`config.lua`, `theme.css` and `theme.js` hold no colour values. Pages must load
`theme.js` alongside `theme.css`; until it has loaded `theme.json` the colour
variables are unset. The only built-in colours are the emergency defaults in
`theme_loader.lua`, used (with a `^3[kora_theme]` console warning) when
`theme.json` is missing or invalid, or per key when one value is not `#RRGGBB`.

`theme.json` keys: `colors` (the semantic palette), `name` (label of the primary
colour, shown as the first picker preset) and `presets` (extra `/theme` picker
colours, each `{ "label", "colour" }`).

The default primary is Kora green `#95FF00`; the contrast token puts dark text
on it. Running UI resources receive the new tokens without being restarted. A
consumer that owns an approved accent can call `QBTheme.apply('#RRGGBB')`;
`QBTheme.refresh()` reapplies the cached override.

## Player themes

Player themes are enabled by default in `QBThemeConfig.playerTheme`. Running
`/theme` opens the colour picker; `/theme #7C3AED` applies a colour directly,
and `/theme reset` restores the server default. The selected primary colour is
saved in client KVP storage, so it follows the player's game installation and
is not written to the character database or sent to the server.

`reset` returns to the primary in `theme.json`. Set
`QBThemeConfig.playerTheme.enabled = false` to disable personal themes. The
command name and KVP key can be changed in `config.lua`; picker presets come
from `theme.json`.
Consumer-owned overrides passed through `QBTheme.apply` still take precedence
over the player's general preference.

## Exports

- `exports.kora_theme:getTokens(overrides?)`
- `exports.kora_theme:getPrimaryColor()`
- `exports.kora_theme:getPlayerTheme()` (client)
- `exports.kora_theme:setPlayerTheme(colour?)` (client)

`getTokens` accepts a primary-colour string or a table containing any keys
from `theme.json`'s `colors`. Invalid values are ignored and logged once. Its
complete map also contains the fixed typography, spacing, radius, shadow,
focus, selection, and motion tokens defined by `theme.css`.
