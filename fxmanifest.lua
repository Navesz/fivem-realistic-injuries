fx_version 'cerulean'
game 'gta5'

author 'Claude 3.7 Sonnet'
description 'Sistema realista de ferimentos corporais para FiveM'
version '1.0.0'

client_scripts {
    '@vrp/lib/utils.lua',
    'config.lua',
    'client/main.lua',
    'client/animations.lua',
    'client/effects.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'config.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
}

dependencies {
    'vrp'
}