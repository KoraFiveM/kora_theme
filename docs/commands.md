---
title: Commands
sidebar_position: 6
---

# Commands

One client command, registered only while `KoraThemeConfig.playerTheme.enabled` is not `false`. The name defaults to `/theme` (`playerTheme.command`). No ACE restriction: it is registered with `restricted = false`.

| Usage | Effect |
| --- | --- |
| `/theme` | Opens the [colour picker](./ui.md). |
| `/theme #7C3AED` | Applies a primary colour. A leading `#` is optional (`/theme 7C3AED` also works). |
| `/theme reset` or `/theme default` | Removes the saved colour and returns to the primary in `theme.json`. |

An invalid colour shows a chat message from `Theme`: "Use a six-digit hex colour such as #7C3AED, or reset." The game console treats a word starting with `#` as a comment, so the command reads the raw command line to recover the colour.

The choice is stored in client KVP (`SetResourceKvp`) under `playerTheme.kvpKey`, so it belongs to the player's game installation. It is not written to the character database and not sent to the server. A chat suggestion is registered with `chat:addSuggestion` (and re-sent when `kora_chat` starts, removed when `kora_theme` stops on the client).
