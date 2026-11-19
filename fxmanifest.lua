fx_version 'cerulean'
game 'gta5'

name 'sxWaink'
description 'Vehicle scanner app for lb-phone with an in game crosshair and vehicle widget'
author '0xS4cha'
version '1.0.0'
repository 'https://github.com/0xS4cha/sxWaink'

lua54 'yes'

dependencies {
    'lb-phone',
}

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
    'modules/**/cl_*.lua',
    'core/sh_init.lua',
}

server_scripts {
    'core/sh_init.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
