fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Huso'
description 'Endcore RP - Polis tableti: ihbarlar, görevdeki ekip, önemli konumlar'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_script 'server.lua'
client_script 'client.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}
