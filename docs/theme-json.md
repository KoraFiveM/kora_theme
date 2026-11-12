---
title: theme.json
sidebar_position: 6
---

# theme.json

`theme.json` is the only place colours, shape and font choices are edited. It is read by `theme_loader.lua` (server and client Lua, via `LoadResourceFile` and `json.decode`) and fetched by `theme.js` in the browser. Restart `kora_theme` after editing it; UIs of other resources pick up the new tokens without being restarted.

## Keys

| Key | Meaning |
| --- | --- |
| `name` | Label of the primary colour. Shown as the first `/theme` picker preset. Falls back to `Server default` when empty or missing. |
| `colors` | Required object with the semantic palette (below). |
| `shape` | Optional corners and shadows. |
| `presets` | Extra picker colours, each `{ "label": "...", "colour": "#RRGGBB" }`. |
| `fonts` | Font choice per slot. See [Fonts](./fonts.md). |

If `theme.json` is missing, unreadable, or has no `colors` object, the Lua side uses built-in emergency colours (identical to the shipped palette) and prints a yellow `[kora_theme]` warning. A single colour that is not `#RRGGBB` falls back to its emergency default with a warning. Colours are normalised to upper case.

## Colours

All 17 keys under `colors` must be six-digit hex values:

`background`, `surface`, `surfacePopover`, `surfaceRaised`, `surfaceHover`, `foreground`, `mutedForeground`, `border`, `borderStrong`, `control`, `controlHover`, `primary`, `success`, `warning`, `danger`, `info`, `armour`.

The shipped primary is Kora green `#95FF00`. `theme.js` has no fallback palette: a colour missing from `theme.json` leaves its CSS variables unset in the browser. The primary foreground (and the foreground of success, warning, danger and info) is chosen automatically as white or a fixed dark grey, whichever contrasts better.

## Shape

```json
"shape": { "radius": 8, "shadows": "soft" }
```

- `radius` - base corner size in px, clamped to 0 to 24. The small corner is 75 percent and the large corner 125 percent of it.
- `shadows` - `"soft"` (lighter shadows) or `"none"`. Any other value logs a warning and keeps the default.

Both are optional. Without `shape` the `theme.css` defaults apply (`0.625rem` corners and heavier shadows).

## Presets

```json
"presets": [
  { "label": "Crimson", "colour": "#DC143C" }
]
```

Entries with a non-hex colour are ignored. The picker shows the server primary first (labelled with `name`), then the presets, skipping duplicates and labels longer than 40 characters.
