---
title: Testing
sidebar_position: 13
---

# Testing

`test/run.sh` runs, in order: the Lua tests `test/theme.lua`, `test/client.lua`, `test/bridge.lua` and `test/config.lua` (`LUA` can name the interpreter), the Node scripts `test/theme-js.cjs` and `test/vite-plugin.mjs`, and `test/consumers.sh`. `test/json.lua` is a JSON helper for the Lua tests.

`test/consumers.sh` is a workspace check, not a unit test. It expects the Kora development workspace layout (a `server.cfg` and `resources/[test]/...` several levels above the resource) and verifies that `kora_theme` is ensured first, consumers declare the dependency, bridge users import the bridge, and `theme.css` keeps transparent bodies. It fails outside that layout.

`tests/legacy-game.feature` holds manual in-game scenarios for the `kora_qa` panel (registered with `qa_feature` in the manifest): start-up without warnings, the picker, `/theme` colours, fonts and the `/config` editor.
