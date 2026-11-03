fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_theme'
-- Keep the legacy resource name resolvable for exports['qbtheme'] callers.
provide 'qbtheme'
author 'Kora'
version '1.0.0'
description 'Shared design tokens and browser styling for Kora resources'

ui_page 'web/index.html'

files {
    'theme.css',
    'theme.js',
    'theme.json',
    'fonts/**',
    'web/index.html',
    'web/app.js',
    'web/style.css',
    'client/bridge.lua',
    'vite-plugin.mjs',
}

shared_scripts {
    'theme_loader.lua',
    'config.lua',
    'shared.lua',
}

client_script 'client/main.lua'
