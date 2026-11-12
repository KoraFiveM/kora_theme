# kora_theme agent guide

`kora_theme` is the shared design system for Kora NUI resources: `theme.json` (single source of colours, shape and fonts), `theme.css`/`theme.js` (browser runtime), `fonts/` (bundled OFL fonts and `catalog.json`), `theme_loader.lua`/`config.lua`/`shared.lua` (shared Lua: loader, behaviour config, token exports), `client/main.lua` (`/theme` command and picker), `client/bridge.lua` (imported by consumers), `web/` (picker UI), `vite-plugin.mjs`, `test/` (offline tests) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first for an overview of features, configuration, commands, exports, events and tokens.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
