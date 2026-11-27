fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Huso'
description 'Polis noktalarına yer işareti + yerleştirilebilir NPC memurlar'

shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'qbx_police',
}
