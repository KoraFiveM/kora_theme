---
title: Fonts
sidebar_position: 4
---

# Fonts

UIs use three CSS variables: `--font-sans` (body), `--font-heading` (headings) and `--font-mono`. The `theme.css` defaults are the original system stacks, so nothing changes until a font is chosen.

## Choosing fonts in theme.json

```json
"fonts": { "heading": "oswald", "body": "poppins", "mono": "default" }
```

Each slot (`heading`, `body`, `mono`) is one of:

- `"default"` - the built-in stack. A default heading follows the body font.
- an id from `fonts/catalog.json`.
- a plain CSS font-family list such as `"Arial, sans-serif"`.

A custom list may only contain letters, digits, spaces, commas, quotes and hyphens, at most 200 characters, with balanced quotes and at least one letter. The slot's default stack is appended as a fallback. An invalid value logs a `[kora_theme]` warning and falls back to the default.

## Bundled fonts

Latin subset woff2 files from `@fontsource`, each folder with its `OFL.txt` (OFL-1.1).

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

The `@font-face` families have a `Kora ` prefix (for example `"Kora Poppins"`) so the default stack's `Inter` still resolves to the system font. Browsers download a file only once a stack uses it.

## Precedence

Per slot: custom family from `/config`, then the `/config` dropdown, then `theme.json`, then the built-in default. The `source` of each resolved font from `getFonts` is `config`, `theme.json` or `default`.

## Adding a font

1. Copy an OFL-licensed latin woff2 file and its licence into `fonts/<id>/` (lowercase letters, digits and hyphens).
2. Add an `@font-face` rule to `fonts/fonts.css` with a `Kora <Name>` family, a relative `url()` and `font-display: swap`.
3. Add an entry with `id`, `label`, `kind` (`sans` or `mono`), `family` and `stack` to `fonts/catalog.json`. The stack should start with the family and end with the matching default stack. The catalog loader ignores entries with a duplicate id, the id `default`, or an id that is not lowercase letters, digits and hyphens.

The monospace dropdown in `/config` lists only fonts of kind `mono`; the other two list every font.
