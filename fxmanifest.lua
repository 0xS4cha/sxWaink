fx_version 'cerulean'
game 'gta5'

name 'sxWaink'
description 'Vehicle scanner with an in game crosshair, a vehicle widget, owner lookup and an optional lb-phone app, ESX or standalone'
author '0xS4cha'
version '1.0.0'
repository 'https://github.com/0xS4cha/sxWaink'

lua54 'yes'

dependency 'sxHelpMenu'

shared_scripts {
    'core/sh_logger.lua',
    'core/sh_translation.lua',
    'translations/*.lua',
    'core/sh_modules.lua',
    'core/sh_class.lua',
    'core/sh_callback.lua',
    'core/sh_generate.lua',
    'core/sh_utils.lua',
    'shared/config.lua',
}

client_scripts {
    'bridge/cl_bridge.lua',
    'modules/**/cl_*.lua',
    'core/sh_init.lua',
}

server_scripts {
    'bridge/sv_bridge.lua',
    'modules/**/sv_*.lua',
    'core/sh_init.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
