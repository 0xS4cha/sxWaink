Config = {}

Config.Framework = 'auto'

Config.Units = 'auto'

Config.Keys = {
    toggle = 'F9',
    nextPage = 'R',
}

Config.Phone = {
    enabled = true,
    identifier = 'Waink',
    name = 'Waink',
    developer = '0xS4cha',
    defaultApp = true,
    price = 0,
}

Config.Animation = {
    enabled = true,
    prop = 'prop_npc_phone_02',
    bone = 28422,
    offset = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
    onFoot = { dict = 'amb@world_human_mobile_film_shocking@female@base', name = 'base' },
    inVehicle = { dict = 'cellphone@in_car@ds', name = 'cellphone_text_read_base' },
}

Config.Access = {
    jobs = {},
    ace = 'sxwaink.use',
}

Config.Scan = {
    distance = 40.0,
    duration = 1500,
    decay = 0.5,
    cooldown = 3000,
    widgetDuration = 15000,
}

Config.Owner = {
    enabled = true,
    cacheSeconds = 60,
}

Config.HistoryLimit = 30
