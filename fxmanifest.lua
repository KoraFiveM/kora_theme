fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_theme'
author 'qbcore2'
version '0.1.0'
description 'Shared design tokens and browser styling for qbcore2 resources'

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

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
