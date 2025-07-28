fx_version 'cerulean'
game 'gta5'

author 'NRG Development'
description 'In-game report system with ESX and QBCore compatibility'
version '1.1.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/notifications.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/tickets.lua',
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/*.png',
    'ui/assets/*.svg',
}

lua54 'yes'
