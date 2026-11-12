---
title: Troubleshooting
sidebar_position: 15
---

# Troubleshooting

## Yellow `[kora_theme]` warnings at start

They name the problem: `theme.json` missing or invalid, a colour not in `#RRGGBB` form, an invalid font or shape value, or `fonts/catalog.json` missing. The resource keeps running with built-in defaults. Fix the file and restart `kora_theme`.

## UI has no colours

The page must load `theme.js` as well as `theme.css`. Until `theme.json` is fetched the variables are unset; if it cannot be loaded after 40 retries the console shows `could not load theme.json`.

## A colour edit does not show

Restart `kora_theme`. Browsers use the NUI cache; consumers using the Vite plugin get a versioned `theme.js` URL.

## `/theme` is unknown

Player themes are disabled (`playerTheme.enabled = false`), or `playerTheme.command` was renamed.

## Font settings missing in /config

They appear only after `kora_lib` has started and exposes `modules/config/consumer.lua`. Start `kora_lib`, or restart `kora_theme` after it. If loading fails, a message beginning `[kora_theme] Could not load the kora_lib configuration bridge` is printed.

## Custom font not applied

A custom family must pass the character rules in [Fonts](./fonts.md), and the font must be installed on the player's PC or bundled in `fonts/`.

## Colour typed in the console

The console treats `#` as a comment start; the command reads the raw line to recover it. If a colour is still ignored, try `/theme 7C3AED` without the hash.
