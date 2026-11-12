---
title: Configuration
sidebar_position: 5
---

# Configuration

Colours, shape, presets and `theme.json` fonts are configured in [theme.json](./theme-json.md). `config.lua` holds only behaviour options in the global `KoraThemeConfig`.

## playerTheme

| Option | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Enables personal themes and the `/theme` command. When `false`, no command is registered, `getPlayerTheme` returns `nil` and `setPlayerTheme` returns `false` with an error message. Read once when the client script starts. |
| `command` | `'theme'` | Command name (without the slash). |
| `kvpKey` | `'kora_theme:playerTheme'` | Resource KVP key where the colour is stored. |

Empty or non-string `command` / `kvpKey` values fall back to the defaults. See [Commands](./commands.md).

## fonts

| Option | Default | Description |
| --- | --- | --- |
| `heading`, `body`, `mono` | `'theme'` | `'theme'` follows `theme.json`; `'default'` is the built-in stack; any other value is an id from `fonts/catalog.json`. |
| `custom.heading`, `custom.body`, `custom.mono` | `''` | Optional CSS font-family list that overrides the choice for that slot (same character rules as in [Fonts](./fonts.md)). |

These values can be changed live from the in-game `/config` editor once `kora_lib` is running. The `config.lua` script registers the descriptors (dropdowns named **Body font**, **Heading font** and **Monospace font**; advanced text fields named **Custom ... family**) with `kora_lib`, and raises the local event `kora_theme:fontsChanged` whenever one changes. Editing requires the permission enforced by `kora_lib` (the original README names the `kora_lib.config.edit` ACE; this is checked by `kora_lib`, not by this resource). The generated per-server overrides are stored by `kora_lib` in `config.local.lua` according to `.gitignore`; that behaviour belongs to `kora_lib` and is not verified here.

Precedence is described in [Fonts](./fonts.md).
