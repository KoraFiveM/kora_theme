---
title: Vite plugin
sidebar_position: 12
---

# Vite plugin

`vite-plugin.mjs` is listed in the manifest `files` so consumer builds can import it. It exports a default function returning a Vite plugin named `kora_theme`.

- **HTML transform** - replaces the placeholder `__KORA_THEME_BASE__` in `index.html` with `/@kora_theme` when running `vite serve`, or with `https://cfx-nui-kora_theme` in builds. It appends `?v=<runtimeVersion>` to the `theme.js` URL (currently `5`) so CEF does not keep an old loader.
- **Dev server** - serves `theme.css`, `theme.js`, `theme.json` and files under `fonts/` (`.css`, `.json`, `.woff2`, `.txt`) at `/@kora_theme/...` with `Cache-Control: no-store`, so the dev server shows the same palette as the resource.

Example in a consumer page:

```html
<link rel="stylesheet" href="__KORA_THEME_BASE__/theme.css" />
<script src="__KORA_THEME_BASE__/theme.js" defer></script>
```
