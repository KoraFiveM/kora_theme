---
title: Design tokens
sidebar_position: 11
---

# Design tokens

`theme.js` sets these CSS variables on the root element from `theme.json`; `getTokens` returns the same values in Lua (HSL triplets such as `84 100% 50%`, without the `hsl()` wrapper). Use them as `hsl(var(--primary))`.

## Colour tokens

- Surfaces and text: `background`, `foreground`, `card`, `card-foreground`, `popover`, `popover-foreground`, `secondary`, `secondary-foreground`, `muted`, `muted-foreground`, `accent`, `accent-foreground`, `surface`, `surface-raised`, `surface-hover`, `surface-panel`, `hud`, `modal-overlay`, `secondary-text`.
- Borders and controls: `border`, `border-strong`, `input`, `control-border`, `control-border-hover`.
- Primary: `primary`, `primary-foreground`, `ring`, `focus-ring`, `selection`, `brand-hover`, `brand-pressed`, `brand-soft`, `brand-border`.
- Status: `success`, `warning`, `destructive`, `danger`, `info`, `armour`, plus `-soft`, `-border` and `-foreground` variants for success, warning, destructive and info.

## Fixed tokens (theme.css)

- Fonts: `font-sans`, `font-heading`, `font-mono`.
- Spacing: `space`, `space-1`, `space-2`, `space-3`, `space-4`, `space-6`.
- Shape: `radius-sm`, `radius`, `radius-lg`, `radius-full`, `shadow-low`, `shadow-floating`, `shadow-modal` (overridden by `theme.json` `shape`).
- Motion: `duration-fast`, `duration-popover`, `duration-dialog`, `ease-entry`. Reduced-motion is handled in `theme.css`.

## Component rules

`theme.css` styles buttons, inputs, selects, textareas, dialogs, tables, `kbd`, `progress` and scrollbars. Data attributes select variants: `data-variant` of `primary`, `destructive` or `ghost` on buttons; `data-size` of `sm` or `lg`; `data-invalid="true"` on inputs; and `data-ui="badge"` with `data-variant` of `primary`, `success`, `warning`, `destructive` or `info`. Document bodies are forced transparent so NUI never paints a fullscreen backdrop.
