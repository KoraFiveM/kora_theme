---
title: Installation
sidebar_position: 2
---

# Installation

1. Place `kora_theme` in your resources folder.
2. Ensure it before every resource that has a browser UI:

   ```cfg
   ensure kora_theme
   ensure kora_lib
   ```

3. In each consumer resource's `fxmanifest.lua`, declare the dependency:

   ```lua
   dependency 'kora_theme'
   ```

4. Edit [theme.json](./theme-json.md) if you want a different palette, then restart `kora_theme`.

## Dependencies

`fxmanifest.lua` declares no dependencies. Optional integrations:

| Resource | Used for |
| --- | --- |
| `kora_lib` | Registers the live font settings for `/config`. `kora_lib` itself depends on `kora_theme`, so `kora_theme` cannot declare it; `config.lua` waits for `kora_lib` to start and loads `modules/config/consumer.lua` from it. Without `kora_lib` the resource still works and `KoraThemeConfig` stays a plain table. |
| `kora_chat` (or any resource providing `chat:addSuggestion`) | Shows the `/theme` suggestion. Suggestions are re-sent when `kora_chat` starts. |

There is no SQL and no item or ACE setup. Fonts need no extra setup because they ship in `fonts/`.

## What is not shipped

`config.local.lua` and `config.local.lua.bak` are ignored by git (see `.gitignore`); they are described there as generated per-server `kora_lib` configuration overrides.
