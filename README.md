# kora_theme

Shared dark design system for qbcore2 browser UIs. Start this resource before
all UI resources and declare `dependency 'qbtheme'` in each consumer.

Browser pages load `https://cfx-nui-qbtheme/theme.css` and `theme.js`. Resources
with a persistent private UI frame import `@kora_theme/client/bridge.lua` for live
refresh behavior. A loading screen whose frame is permanently shut down does
not keep that Lua bridge, and headless AppShell consumers pass their accent to
kora_lib instead of sending NUI messages from their own resource.

Change the semantic hex colours in `theme.json`, then restart `kora_theme`.
Running UI resources receive the new tokens without being restarted. A
consumer that owns an approved accent can call `QBTheme.apply('#RRGGBB')`;
`QBTheme.refresh()` reapplies the cached override.

## Player themes

Player themes are enabled by default in `QBThemeConfig.playerTheme`. Running
`/theme` opens the colour picker; `/theme #7C3AED` applies a colour directly,
and `/theme reset` restores the server default. The selected primary colour is
saved in client KVP storage, so it follows the player's game installation and
is not written to the character database or sent to the server.

Set `QBThemeConfig.playerTheme.enabled = false` to disable personal themes.
The command name, KVP key, and displayed presets can be changed in `config.lua`.
Consumer-owned overrides passed through `QBTheme.apply` still take precedence
over the player's general preference.

## Exports

- `exports.kora_theme:getTokens(overrides?)`
- `exports.kora_theme:getPrimaryColor()`
- `exports.kora_theme:getPlayerTheme()` (client)
- `exports.kora_theme:setPlayerTheme(colour?)` (client)

`getTokens` accepts a primary-colour string or a table containing any keys
from `QBThemeConfig.colors`. Invalid values are ignored and logged once. Its
complete map also contains the fixed typography, spacing, radius, shadow,
focus, selection, and motion tokens defined by `theme.css`.
