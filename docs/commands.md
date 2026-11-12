---
title: "Commands"
sidebar_position: 4
---


# Commands

One client command, registered directly with `RegisterCommand` (not through kora_core), present only while `KoraThemeConfig.playerTheme.enabled` is true.

## Built-in commands

### `/theme [colour]`

With no argument, opens the colour-picker NUI. With an argument, sets (or clears) the player's personal accent colour directly without opening the UI.

| Field | Details |
| --- | --- |
| Context | In-game · client command |
| Arguments | colour? — optional. A 6-digit hex colour (`#` optional, case-insensitive), or the word `reset`/`default` to clear the override and follow the server's colour again. |
| Access | Any player. This is a purely client-side, per-player preference stored in that client's own KVP storage — it is never sent to the server and never affects any other player's view. |

**Example**

```text
/theme
/theme 7C3AED
/theme reset
```

**Result**

Opens the picker, or applies/clears the colour immediately across every open Kora NUI on that client. An invalid colour string shows a chat message: `Use a six-digit hex colour such as #7C3AED, or reset.`

## Command name and key are configurable

`KoraThemeConfig.playerTheme.command` renames `/theme` (default `'theme'`); `KoraThemeConfig.playerTheme.kvpKey` changes the KVP storage key (default `'kora_theme:playerTheme'`). Setting `KoraThemeConfig.playerTheme.enabled = false` removes the command and chat suggestion entirely and keeps every NUI on the server-wide `theme.json` primary colour for everyone.

## Behaviour details

- The command is registered with `restricted = false`, so no ACE permission is needed.
- The game console treats a word starting with `#` as a comment, so the command reads the raw command line to recover the colour (`/theme #7C3AED` arrives without arguments otherwise).
- The choice is stored with `SetResourceKvp` under `playerTheme.kvpKey`, so it belongs to the player's game installation. It is not written to the character database and not sent to the server.
- A chat suggestion is registered with `chat:addSuggestion`, re-sent when `kora_chat` starts. See the [colour picker](./ui.md) and [Events](./events.md).
