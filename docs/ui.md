---
title: Player theme picker
sidebar_position: 11
---

# Player theme picker

The resource's own `ui_page` is `web/index.html`, the **Choose your colour** window opened by `/theme`. It is hidden until opened.

- A row of round swatches: the server primary first (named by `theme.json` `name`), then the `presets`. Clicking one applies it immediately.
- A **Custom colour** input with an **Apply** button.
- **Use server default** removes the personal colour.
- **Done**, the close button or Escape closes the window and returns mouse and camera control (`SetNuiFocus(false, false)`).

Errors (for example an invalid colour) appear under the buttons. The window is disabled entirely when `playerTheme.enabled` is `false` (no command opens it). Other resources' UIs update as soon as a colour is applied, through [`kora_theme:playerThemeChanged`](./events.md).
