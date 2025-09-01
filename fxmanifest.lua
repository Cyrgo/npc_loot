fx_version 'cerulean'
game 'gta5'

description 'QBX NPC Body Looting System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'