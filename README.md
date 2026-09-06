# qbtheme

Shared dark design system for qbcore2 browser UIs. Start this resource before
all UI resources and declare `dependency 'qbtheme'` in each consumer.

Browser pages load `https://cfx-nui-qbtheme/theme.css` and `theme.js`. Their
resource manifests import `@qbtheme/client/bridge.lua`, which provides the
`qbtheme:ready` callback and live refresh behavior.

Change the semantic hex colours in `theme.json`, then restart `qbtheme`.
Running UI resources receive the new tokens without being restarted. A
consumer that owns an approved accent can call `QBTheme.apply('#RRGGBB')`;
`QBTheme.refresh()` reapplies the cached override.

## Exports

- `exports.qbtheme:getTokens(overrides?)`
- `exports.qbtheme:getPrimaryColor()`

`getTokens` accepts a primary-colour string or a table containing any keys
from `QBThemeConfig.colors`. Invalid values are ignored and logged once. Its
complete map also contains the fixed typography, spacing, radius, shadow,
focus, selection, and motion tokens defined by `theme.css`.
