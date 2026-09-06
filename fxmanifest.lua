fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbtheme'
author 'qbcore2'
version '1.0.0'
description 'Shared design tokens and browser styling for qbcore2 resources'

ui_page 'web/index.html'

files {
    'theme.css',
    'theme.js',
    'theme.json',
    'web/index.html',
    'web/app.js',
    'web/style.css',
    'client/bridge.lua',
    'vite-plugin.mjs',
}

shared_scripts {
    'config.lua',
    'shared.lua',
}

client_script 'client/main.lua'
