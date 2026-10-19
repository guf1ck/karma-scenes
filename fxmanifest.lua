fx_version 'cerulean'
game 'gta5'

author 'ANTUNES'
description 'Karma Developments Scenes V System - for QBCore, ESX, Qbox and Standalone'
version '1.0.1'

lua54 'yes'

dependency '/onesync'

shared_scripts {
    'config.lua',
    'shared/validation.lua'
}

client_scripts {
    'client/notify.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/fonts/*.ttf',
    'web/fonts/Barlow-OFL.txt'
}